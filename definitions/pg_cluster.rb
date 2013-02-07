# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql cookbook
# Resource:: cluster

# Create redis configuration with instance running
#
# :copyright: (c) 2013 by Alexandr Lispython (alex@obout.ru).
# :license: BSD, see LICENSE for more details.
# :github: https://github.com/Lispython/chef-postgresql
#

define :pg_cluster,
       :name => nil,
       :version => nil,
       :action => "create",
       :config => {},
       :standby => {},
       :locale => "en_US.UTF-8",
       :lc => {},
       :start => true,
       :port => nil,
       :start_config => "auto" do

  Chef::Log.info("Creating #{params[:name]} on #{params[:version]}")


  config_path = "#{node[:postgresql][:config_dir]}/#{params[:version]}/#{params[:name]}"
  start_file = "#{config_path}/start.conf"
  data_dir = "#{node[:postgresql][:data_dir]}/#{params[:version]}/#{params[:name]}"
  pid_file = "#{node[:postgresql][:data_run]}/#{params[:version]}-#{params[:name]}.pid"
  ident_file = "#{config_path}/pg_ident.conf"
  hba_file = "#{config_path}/pg_hba.conf"
  config_file = "#{config_path}/postgresql.conf"
  data_run = node[:postgresql]["data_run"]

  config = Chef::Mixin::DeepMerge.merge(node[:postgresql]["config"].to_hash, params[:config][:config])
  standby = params[:standby] || {}

  cluster_options = []
  cluster_options << "--locale #{params[:locale]}" if params[:locale]
  params[:lc].each() do |key, value|
    cluster_options << "--lc-#{key} #{value}" if value
  end

  cluster_options << "--start" if params[:start]
  cluster_options << "--start-conf=#{params[:start_config]}" if params[:start_config]
  cluster_options << "--port=#{params[:config][:port]}" if params[:config][:port]

  create_cluster = begin
                     "pg_createcluster #{cluster_options.join(' ')} #{params[:version]} #{params[:name]}"
                   end

  Chef::Log.info("Creating postgresql cluster by #{create_cluster}")

  execute "create-cluster-#{params[:version]}-#{params[:name]}" do
    action :run
    user "root"
    command <<-EOH
        #{create_cluster}
      EOH
    not_if do
      ::File.exist?("#{config_file}")
    end
  end

  template "#{config_file}" do
    source "postgresql.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0640
    variables(:port => params[:config][:port],
              :config => config,
              :cluster_name => params[:name],
              :version => params[:version],
              :pid_file => pid_file,
              :ident_file => ident_file,
              :hba_file => hba_file,
              :data_dir => data_dir,
              :data_run => data_run)
    action :create
  end


#   if standby[:allow]
#     # This goes in the data directory; where data is stored
#     node_name = standby[:node_name]
#     master_ip = standby[:master_ip]
#     template "#{data_dir}/recovery.conf" do
#       source "recovery.conf.erb"
#       owner "postgres"
#       group "postgres"
#       mode 0600
#       variables(
#                 :primary_conninfo => "host=#{master_ip} application_name=#{node_name}",
#                 :trigger_file => "#{data_dir}")
#     notifies :restart, resources(:service => "postgresql")
#     end
#   end

  template start_file do
    source "pg_start.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0640
    cookbook params[:cookbook]
    variables(:mode => params[:start_config],
              :cluster => params[:name],
              :version => params[:version])
  end

  # Default PostgreSQL install has 'ident' checking on unix user 'postgres'
  # and 'md5' password checking with connections from 'localhost'. This script
  # runs as user 'postgres', so we can execute the 'role' and 'database' resources
  # as 'root' later on, passing the below credentials in the PG client.
  bash "assign-postgres-password-#{params[:name]}-#{params[:port]}" do
    user 'postgres'
    code <<-EOH
echo "ALTER ROLE postgres ENCRYPTED PASSWORD '#{params[:config][:password][:postgres]}';" | psql -h #{node[:postgresql][:data_run]} -p #{params[:port]}
  EOH
    #only_if 'pg_lsclusters -h | awk -F" " \'{ print $1 $2 }\' | grep "#{params[:name]}" | grep "#{params[:version]}"'
    only_if "invoke-rc.d postgresql status | grep #{params[:name]}" # make sure server is actually running
    not_if "echo '\\connect' | PGPASSWORD=#{params[:config]['password']['postgres']} psql --username=postgres --no-password  -h #{node[:postgresql][:data_run]} -p #{params[:port]} "
    action :run
  end

  template hba_file do
    source "pg_hba.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0640
    cookbook params[:cookbook]
    variables(:hba => params[:config][:hba] || node[:postgresql][:hba],
              :standby => standby,
              :cluster => params[:name],
              :version => params[:version])
    only_if do
      ::File.exist?("#{config_file}")
    end
    notifies :reload, resources(:service => "postgresql"), :immediately
  end

end

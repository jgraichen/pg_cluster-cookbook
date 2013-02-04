# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql cookbook
# Resource:: cluster

# Create redis configuration with instance running
#
# :copyright: (c) 2013 by Alexandr Lispython (alex@obout.ru).
# :license: BSD, see LICENSE for more details.
# :github: http://github.com/Lispython/redis-cookbook
#

define :pg_cluster,
       :name => nil,
       :version => nil,
       :action => "create",
       :config => {},
       :standby => {},
       :locale => "en_US.UTF-8",
       :lc => {},
       :start => false,
       :port => nil,
       :start_config => "auto" do

  Chef::Log.info("Creating #{params[:name]} on #{params[:version]}")

  cluster_service = service "postgresql-cluster-#{params[:version]}" do
    service_name "postgresql"
    supports(:start => true,
             :stop => true,
             :restart => true,
             :reload => true,
             :status => true)
    case
    when node['platform_version'].to_f <= 10.04 && node['postgresql']['version'].to_f < 9.0
      start_command "/etc/init.d/postgresql-#{params[:version]} start"
      stop_command "/etc/init.d/postgresql-#{params[:version]} stop"
      status_command "/etc/init.d/postgresql-#{params[:version]} status"
      restart_command "/etc/init.d/postgresql-#{params[:version]} restart"
      reload_command "/etc/init.d/postgresql-#{params[:version]} reload"
    else
      start_command "/etc/init.d/postgresql start #{params[:version]}"
      stop_command "/etc/init.d/postgresql stop #{params[:version]}"
      status_command "/etc/init.d/postgresql status #{params[:version]}"
      restart_command "/etc/init.d/postgresql restart #{params[:version]}"
      reload_command "/etc/init.d/postgresql reload #{params[:version]}"
    end
    action :nothing
  end


  config_path = "#{node[:postgresql][:config_dir]}/#{params[:version]}/#{params[:name]}"
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

  directory data_dir do
      mode 0640
      owner "postgres"
      group "postgres"
      action :create
      recursive true
   end

  execute "create-cluster-#{params[:version]}-#{params[:name]}" do
    action :run
    user "root"
    command <<-EOH
        #{create_cluster}
      EOH
    not_if do
      ::File.exist?("#{config_file}")
    end
    notifies :restart, resources(:service => "postgresql")
    #notifies :stop, resources(:service => "postgresql-cluster-#{params[:version]}"), :immediately
  end

  # template "#{config_file}" do
  #   source "postgresql.conf.erb"
  #   owner "postgres"
  #   group "postgres"
  #   mode 0640
  #   variables(:port => params[:config][:port],
  #             :config => config,
  #             :cluster_name => params[:name],
  #             :version => params[:version],
  #             :pid_file => pid_file,
  #             :ident_file => ident_file,
  #             :hba_file => hba_file,
  #             :data_dir => data_dir,
  #             :data_run => data_run)
  #   action :create
  # end


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
    #notifies :restart, resources(:service => "postgresql-cluster-#{params[:version]}")
    notifies :restart, resources(:service => "postgresql")
  end


  # Default PostgreSQL install has 'ident' checking on unix user 'postgres'
  # and 'md5' password checking with connections from 'localhost'. This script
  # runs as user 'postgres', so we can execute the 'role' and 'database' resources
  # as 'root' later on, passing the below credentials in the PG client.
#   bash "assign-postgres-password-#{params[:name]}-#{params[:port]}" do
#     user 'postgres'
#     code <<-EOH
# echo "ALTER ROLE postgres ENCRYPTED PASSWORD '#{params[:config][:password][:postgres]}';" | psql -h #{node[:postgresql][:data_run]} -p #{params[:port]}
#   EOH
#     only_if "invoke-rc.d postgresql status | grep main" # make sure server is actually running
#     not_if "echo '\connect' | PGPASSWORD=#{params[:config]['password']['postgres']} psql --username=postgres --no-password  #{node[:postgresql][:data_run]} -p #{params[:port]} "
#     action :run
#   end

end

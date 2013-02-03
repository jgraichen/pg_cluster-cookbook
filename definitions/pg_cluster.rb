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
       :version => "8.4",
       :action => "create",
       :config => {},
       :standby => {},
       :locale => "en_US.UTF-8",
       :lc => {} do

  Chef::Log.info("Creating #{params[:name]} on #{params[:version]}")

  config_path = "#{node[:postgresql][:config_dir]}/#{params[:version]}/#{params[:name]}"
  data_path = "#{node[:postgresql][:data_dir]}/#{params[:version]}/#{params[:name]}"

  config = Chef::Mixin::DeepMerge.merge(node["postgresql"]["config"].to_hash, params[:config])
  standby = params[:standby] || {}

  lc_options = []
  lc_options << "--locale #{params[:locale]}" if params[:locale]
  params[:lc].each() do |key,value|
    lc_options << "--lc-#{key} #{value}" if value
  end

  create_cluster = begin
                     "pg_createcluster #{lc_options.join(' ')} #{params[:version]} #{params[:name]}"
                   end

  bash "create_cluster" do
    user "root"
    code <<-EOH
        #{create_cluster}
      EOH

    not_if do
      File.exist?("#{config_path}/postgresql.conf")
    end

  end

  directory config_path do
    owner "postgres"
    group "postgres"
    mode 0600
    recursive true
    action :create
  end

  template "#{config_path}/postgresql.conf" do
    source "postgresql.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0600
    variables(:config => config,
              :cluster_name => params[:name])
    notifies :restart, resources(:service => "postgresql")
  end

  if standby[:allow]
    # This goes in the data directory; where data is stored
    node_name = standby[:node_name]
    master_ip = standby[:master_ip]
    template "#{data_path}/recovery.conf" do
      source "recovery.conf.erb"
      owner "postgres"
      group "postgres"
      mode 0600
      variables(
                :primary_conninfo => "host=#{master_ip} application_name=#{node_name}",
                :trigger_file => "#{data_path}")
    notifies :restart, resources(:service => "postgresql")
    end
  end

  pg_hba "#{params[:name]}" do
    version params[:version]
    config config[:hba]
  end

  # Default PostgreSQL install has 'ident' checking on unix user 'postgres'
  # and 'md5' password checking with connections from 'localhost'. This script
  # runs as user 'postgres', so we can execute the 'role' and 'database' resources
  # as 'root' later on, passing the below credentials in the PG client.
  bash "assign-postgres-password" do
    user 'postgres'
    code <<-EOH
echo "ALTER ROLE postgres ENCRYPTED PASSWORD '#{config[:password][:postgres]}';" | psql -h #{params[:host] || '127.0.0.1'} -p #{params[:port]}
  EOH
    only_if "invoke-rc.d postgresql status | grep main" # make sure server is actually running
    not_if "echo '\connect' | PGPASSWORD=#{config['password']['postgres']} psql --username=postgres --no-password -h #{params[:host] || '127.0.0.1'} -p #{params[:port]} "
    action :run
end

end

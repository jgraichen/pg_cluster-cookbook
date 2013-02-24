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

  version = params[:version]

  config_path = "#{node[:postgresql][:config_dir]}/#{version}/#{params[:name]}"
  start_file = "#{config_path}/start.conf"
  data_dir = "#{node[:postgresql][:data_dir]}/#{version}/#{params[:name]}"
  pid_file = "#{node[:postgresql][:data_run]}/#{version}-#{params[:name]}.pid"
  ident_file = "#{config_path}/pg_ident.conf"
  hba_file = "#{config_path}/pg_hba.conf"
  config_file = "#{config_path}/postgresql.conf"
  data_run = node[:postgresql]["data_run"]
  server_key = File.join(data_dir, 'server.key')

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
                     "pg_createcluster #{cluster_options.join(' ')} #{version} #{params[:name]}"
                   end

  Chef::Log.info("Creating postgresql cluster by #{create_cluster}")

  execute "create-cluster-#{version}-#{params[:name]}" do
    action :run
    user "root"
    command <<-EOH
        #{create_cluster}
      EOH
    not_if do
      ::File.exist?("#{config_file}")
    end
  end

  case node['platform']
  when "ubuntu"
    case
      # PostgreSQL 9.1 on Ubuntu 10.04 gets set up as "postgresql", not "postgresql-9.1"
      # Is this because of the PPA? And is this still the case?
    when node['platform_version'].to_f <= 10.04 && version.to_f < 9.0
      service_name = "postgresql-#{version}"
    else
      service_name = "postgresql"
    end
  when "debian"
    case
    when node['platform_version'].to_f <= 5.0
      service_name = "postgresql-#{version}"
    else
      service_name = "postgresql"
    end
  end

  postgresql_service = service "postgresql-#{version}" do
    service_name service_name
    start_command "/etc/init.d/#{service_name} start #{version}"
    stop_command "/etc/init.d/#{service_name} stop #{version}"
    status_command "/etc/init.d/#{service_name} status #{version}"
    restart_command "/etc/init.d/#{service_name} restart #{version}"
    reload_command "/etc/init.d/#{service_name} reload #{version}"
    supports(:restart => true,
             :status => true,
             :reload => true,
             :stop => true,
             :restart => true)
    action :nothing
  end

  template "#{config_file}" do
    source "postgresql.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0640
    variables(:port => params[:config][:port],
              :config => config,
              :cluster_name => params[:name],
              :version => version,
              :pid_file => pid_file,
              :ident_file => ident_file,
              :hba_file => hba_file,
              :data_dir => data_dir,
              :data_run => data_run)
    action :create
    notifies :restart, "service[postgresql-#{version}]", :immediately
  end

  if config["authentication"][:ssl] == 'true' &&
      params[:config].has_key?(:ssl_password)

    bash 'generate-ssl-keys-#{params[:name]-#{params[:port]}' do
      user 'postgres'
      group 'postgres'
      cwd data_dir
      # Steps from http://www.howtoforge.com/postgresql-ssl-certificates
      code <<-EOF
      openssl genrsa -des3 -passout pass:#{params[:config][:ssl_password]} -out server.key 1024;
      openssl rsa -passin pass:#{params[:config][:ssl_password]} -in server.key -out server.key;
      chmod 400 server.key;
      openssl req -new -key server.key -days 3650 -out server.crt -x509 -subj '/C=PH/ST=Metro Manila/L=NA/O=Stiltify/CN=stiltify.com/emailAddress=hello@stiltify.com';
    EOF
      not_if { File.exists?(server_key) }
    end
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
              :version => version)
    notifies :restart, "service[postgresql-#{version}]", :immediately

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
    #only_if 'pg_lsclusters -h | awk -F" " \'{ print $1 $2 }\' | grep "#{params[:name]}" | grep "#{version}"'
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
              :version => version)
    only_if do
      ::File.exist?("#{config_file}")
    end
    notifies :restart, "service[postgresql-#{version}]", :immediately
  end
end

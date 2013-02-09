action :install do
  Chef::Log.info("Install postgresql server and client from postgresql apt #{new_resource.name}")

  extra_packages = @new_resource.extra_packages
  version = @new_resource.version
  client_packages = []

  dependencies = []

  case node["platform"]
  when "ubuntu", "debian"
    apt_repository "postgresql-apt" do
      uri "http://apt.postgresql.org/pub/repos/apt/"
      distribution "#{node['lsb']['codename']}-pgdg"
      components ["main"]
      key "http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc"
    end

    apt_preference "pgdg" do
      pin "release o=apt.postgresql.org"
      pin_priority "500"
    end
    package "pgdg-keyring"

    # This repository included fresh libpq
    apt_repository "postgresql-pitti-ppa" do
      uri "http://ppa.launchpad.net/pitti/postgresql/ubuntu"
      distribution node['lsb']['codename']
      components ["main"]
      keyserver "keyserver.ubuntu.com"
      key "8683D8A2"
      action :add
      notifies :run, resources(:execute => "apt-get update"), :immediately
    end
  end

  if version.to_f >=9.2
    client_packages.push("libpq5")
    client_packages.push("libpq-dev")
    client_packages.push("postgresql-client-common")
  end

  package_name = "postgresql-#{version}"
  server_packages = [package_name]
  client_packages.push("postgresql-client-#{version}")

  # Install client packages
  client_packages.each do |client_package|
    package client_package do
      action :install
    end
  end

  # Install server packages
  server_packages.each do |server_package|
    package server_package do
      action :install
    end
  end

  extra_packages.each do |extra_package|
    package extra_package do
      action :install
    end
  end

  case node['platform']
  when "ubuntu"
    if node['platform_version'].to_f <= 10.04 && version.to_f < 9.0
      link "/etc/init.d/postgresql" do
        to "/etc/init.d/postgresql-#{version}"
        link_type :symbolic
      end
    end
  end

  postgresql_service = service "postgresql-#{version}" do
    service_name "postgresql-#{version}"
    #   start_command "/etc/init.d/#{service_name} start"
    #   stop_command "/etc/init.d/#{service_name} stop"
    # #  status_command "/etc/init.d/#{service_name} status"
    #   restart_command "/etc/init.d/#{service_name} restart"
    #   reload_command "/etc/init.d/#{service_name} reload"
    supports :restart => true, :status => true, :reload => true, :stop => true, :restart => true
    action :nothing

  end

end

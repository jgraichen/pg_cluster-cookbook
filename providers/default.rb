action :install do
  Chef::Log.info("Install postgresql server and client from system repository #{new_resource.name}")


  extra_packages = @new_resource.extra_packages
  version = @new_resource.version
  package_name = "postgresql"
  server_packages = []
  client_packages = []

  case node[:platform]
  when "ubuntu"
    # Configure for ubuntu

    if (node[:platform_version].to_f <= 9.04 && version.to_f >= 8.4) || ( node[:platform_version].to_f <= 11.04 && version.to_f > 8.4)
      raise "Can't install postgresql v#{version} on ubuntu #{node[:platform_version]}"
    end

    if node[:platform_version].to_f <= 10.04 && version.to_f >= 8.4
      package_name = "postgresql-#{version}"
    else
      package_name = 'postgresql'
    end
    client_packages = %w{postgresql-client libpq-dev}
    server_packages = [package_name]

  when "debian"
    # Configure for debian
    if node[:platform_version].to_f <= 5.0
      version = "8.3"
    elsif node[:platform_version].to_f == 6.0
      version = "8.4"
    else
      version = "9.1"
    end
    client_packages = %w{postgresql-client libpq-dev}
    server_packages = %w{postgresql}

  when "suse"
    if node[:platform_version].to_f <= 11.1
      version = "8.3"
    else
      version = "8.4"
    end
    client_packages = %w{postgresql-client libpq-dev}
    server_packages = %w{postgresql-server}
  else
    version = version || "8.4"
    server_packages = %w{postgresql}
    client_packages = %w{postgresql}
  end

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

  # case node['platform']
  # when "ubuntu"
  #   if node['platform_version'].to_f <= 10.04 && version.to_f < 9.0
  #     link "/etc/init.d/postgresql" do
  #       to "/etc/init.d/postgresql-#{version}"
  #       link_type :symbolic
  #     end
  #   end
  # end

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

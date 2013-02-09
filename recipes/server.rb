# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql
# Recipe:: server
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)#
# Copyright 2009-2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Chef::Log.info("Install postgresql servers")
node[:postgresql][:clusters].collect{|key, value|
  [value["version"], value["extra_packages"]]}.each do |version, extra_packages|

  Chef::Log.info("Process postgresql v#{version}")
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

  postgresql "postgresql-#{version}" do
    version version
    extra_packages extra_packages
    provider node["postgresql"]["provider"]
    action :install
  end
end


node["postgresql"]["clusters"].each() do |cluster_name, config|
  pg_cluster cluster_name do
    version config["version"] || node["postgresql"]["version"]
    standby config["standby"] || node["postgresql"]["standby"]
    locale config["locale"] || node["postgresql"]["locale"]
    config config
    host config[:host]
    port config[:port]
  end
end

# Copy data files from master to standby. Should only happen once.
# if node[:postgresql][:master] && (not node[:postgresql][:standby_ips].empty?)
#   node[:postgresql][:standby_ips].each do |address|
#     bash "Copy Master data files to Standby" do
#       user "root"
#       cwd "/var/lib/postgresql/#{node[:postgresql][:version]}/main/"
#       code <<-EOH
#         invoke-rc.d postgresql stop
#         rsync -av --exclude=pg_xlog * #{address}:/var/lib/postgresql/#{node[:postgresql][:version]}/main/
#         touch .initial_transfer_complete
#         invoke-rc.d postgresql start
#       EOH
#       not_if do
#         File.exists?("/var/lib/postgresql/#{node[:postgresql][:version]}/main/.initial_transfer_complete")
#       end
#     end
#   end
# end

# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql cookbook
# Definition:: pg_hba
#
# Create cluster pg_hba
#
# :copyright: (c) 2013 by Alexandr Lispython (alex@obout.ru).
# :license: BSD, see LICENSE for more details.
# :github: http://github.com/Lispython/chef-postgresql
#

define :pg_hba,
       :name => nil,
       :pg_version => nil,
       :cluster => nil,
       :cookbook => "postgresql",
       :config => {},
       :stand_by => {},
       :action => :create,
       :stand_by_ips => {} do

  Chef::Log.info("Creating pg_hba for cluster #{params[:name]} - #{params[:pg_version]}")
  config = params[:config] || node["postgresql"]["hba"]
  path = "#{node[:postgresql][:config_dir]}/#{params[:pg_version]}/#{params[:name]}/pg_hba.conf"

  template path do
    source "pg_hba.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0600
    notifies :reload, resources(:service => "postgresql"), :immediately
    cookbook params[:cookbook]
    variables(:hba => config,
              :stand_by => params[:stand_by])
  end
end

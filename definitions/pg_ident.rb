# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql cookbook
# Definition:: pg_ident
#
# Create cluster pg_hba
#
# :copyright: (c) 2013 by Alexandr Lispython (alex@obout.ru).
# :license: BSD, see LICENSE for more details.
# :github: http://github.com/Lispython/chef-postgresql
#

define :pg_ident,
       :name => nil,
       :version => "8.4",
       :cluster => nil,
       :file_path => nil,
       :cookbook => "postgresql",
       :config => {} do

  config = params[:config]
  path = "#{node[:postgresql][:config_dir]}/#{params[:version]}/#{params[:cluster]}/pg_ident.conf"

  template path do
    source "pg_ident.conf.erb"
    owner "postgres"
    group "postgres"
    mode 0600
    notifies :reload, resources(:service => "postgresql"), :immediately
    cookbook params[:cookbook]
    variables(:config => config)
  end
end

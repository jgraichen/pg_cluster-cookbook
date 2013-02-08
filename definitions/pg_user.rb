# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql cookbook
# Definition:: user
#
# Create postgresql user
#
# :copyright: (c) 2013 by Alexandr Lispython (alex@obout.ru).
# :license: BSD, see LICENSE for more details.
# :github: http://github.com/Lispython/chef-postgresql
#

define :pg_user,
       :username => nil,
       :superuser => false,
       :create_db => false,
       :create_role => false,
       :encrypted => false,
       :password => "password",
       :host => nil,
       :port => nil do

  username = params[:username] || params[:name]
  port = params[:port]

  user_options = []
  user_options << params[:superuser] ? '--superuser' : '--no-superuser'
  user_options << params[:create_db] ? '--createdb' : '--no-createdb'
  user_options << params[:create_role] ? '--createrole' : '--no-createrole'
  user_options << params[:encrypted] ? '--encrypted' : '--unencrypted'

  user_command = begin
                   "sudo -u postgres createuser -h #{node[:postgresql][:data_run]} -p #{port} #{user_options.join(' ')} #{username};"
                 end
  Chef::Log.info("Creating user by command #{user_command}")

  set_password_command = begin
                           "sudo -u postgres psql -h #{node[:postgresql][:data_run]} -p #{port} -c \"ALTER USER #{username} " +
                             "WITH PASSWORD '#{params[:password]}';\""
                         end

  Chef::Log.info("Setting password command #{set_password_command}")


  bash "create_user-#{username}-#{port}" do
    user "root"
    code <<-EOH
        #{user_command} #{set_password_command}
      EOH
    not_if "sudo -u postgres psql -h #{node[:postgresql][:data_run]} -p #{port} -c \"\\du\" | grep #{username}"
  end
end

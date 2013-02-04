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

define :create_pg_user,
       :username => nil,
       :superuser => false,
       :password => "password",
       :host => nil,
       :port => nil do

  username = params[:username] || params[:name]
  port = params[:port]

  user_command = begin
                   if params[:superuser]
                     "sudo -u postgres createuser -h #{node[:postgresql][:data_run]} -p #{port} -s #{username};"
                   else
                     "sudo -u postgres createuser -h #{node[:postgresql][:data_run]} -p #{port} #{username};"
                   end

                 end

  set_password_command = begin
                           "sudo -u postgres psql -h #{node[:postgresql][:data_run]} -p #{port} -c \"ALTER USER #{username} " +
                             "WITH PASSWORD '#{params[:password]}';\""
                         end

  bash "create_user-#{username}-#{port}" do
    user "root"
    code <<-EOH
        #{user_command} #{set_password_command}
      EOH
    not_if "sudo -u postgres psql -h #{node[:postgresql][:data_run]} -p #{port} -c \"\\du\" | grep #{username}"
  end
end

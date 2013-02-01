# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql cookbook
# Definition:: database
#
# Create postgresql database
#
# :copyright: (c) 2013 by Alexandr Lispython (alex@obout.ru).
# :license: BSD, see LICENSE for more details.
# :github: http://github.com/Lispython/chef-postgresql
#

define :create_pg_database,
       :name => nil,
       :owner => nil,
       :locale => "en_US.UTF-8",
       :template => "template0",
       :encoding => "UTF-8",
       :host => nil,
       :port => nil do

  create_database_command = "sudo -u postgres createdb -E #{params[:encoding]} -O #{params[:owner]} " +
    "--locale #{params[:locale]} -T #{params[:template]} #{params[:name]}"

  bash "create_database" do
    user "root"
    code <<-EOH
        #{create_database_command}
      EOH
    not_if "sudo -u postgres psql -l | grep #{params[:name]}"
  end
end

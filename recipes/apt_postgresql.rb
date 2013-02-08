#
# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql cookbook
# Recipe:: apt_postgresql

# Add official postgresl repository
#
# :copyright: (c) 2013 by Alexandr Lispython (alex@obout.ru).
# :license: BSD, see LICENSE for more details.
# :github: https://github.com/Lispython/chef-postgresql
#


# Add the PostgreSQL 9.1 sources for Ubuntu
# using the official postgresql repository:
# http://apt.postgresql.org/pub/repos/apt/


case node["platform"]
when "ubuntu", "debian"
  apt_repository "postgresql" do
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

end

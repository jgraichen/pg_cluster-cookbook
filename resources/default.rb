# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql cookbook
# Resource:: default (postgresql)

# Install postgresql server
#
# :copyright: (c) 2013 by Alexandr Lispython (alex@obout.ru).
# :license: BSD, see LICENSE for more details.
# :github: http://github.com/Lispython/chef-postgresql
#

actions :install

attribute :name, :kind_of => String, :name_attribute => true
attribute :version, :kind_of => String
attribute :extra_packages, :kind_of => Array

def inittialize(*args)
  super
  @action = :install
  @provider = Chef::Provider::Postgresql
end

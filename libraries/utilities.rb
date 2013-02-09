# -*- coding: utf-8 -*-
#
# Cookbook Name:: postgresql cookbook
# Utilities

# Cluster search
#
# :copyright: (c) 2013 by Alexandr Lispython (alex@obout.ru).
# :license: BSD, see LICENSE for more details.
# :github: https://github.com/Lispython/chef-postgresql
#

module Postgresql
  module Base
    def get_cluster_config(clusters_list, version, name)
      clusters_list.each do |cluster|
        if cluster[:name] == name and cluster[:version].to_f == version.to_f
          return cluster
        end
      end
      return nil
    end
  end
end

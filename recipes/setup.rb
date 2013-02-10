#
# Cookbook Name:: postgresql
# Recipe:: setup
#
# Copyright 2012, Coroutine LLC
# Copyright 2013, Alexandr Lispython
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

node["postgresql"]["clusters"].each() do |cluster_config|

  # Fetch the setup items from the Databag; It contains things like Datase users,
  # passwords, DB names and encoding.
  setup_items = []

  if not cluster_config['setup_items']
    next
  end

  cluster_config['setup_items'].each do |itemname|
    databag = node['postgresql']['databag']
    if Chef::Config[:solo]
      i = data_bag_item(databag,  itemname.gsub(/[.]/, '-'))
      setup_items << i
    else
      item = "id:#{itemname}"

      search(databag, item) do |i|
        setup_items << i
      end
    end
  end

  setup_items.each do |setup|

    setup["users"].each do |user|

      pg_user "#{user['username']}-#{cluster_config[:port]}-#{cluster_config[:name]}" do
        username user['username']
        password user['password']
        superuser user['superuser']
        create_role user['create_role']
        create_db user['create_db']
        encrypted user['encrypted']
        host cluster_config["host"]
        port cluster_config["port"]
      end
    end

    setup["databases"].each do |db|

      pg_database db['name'] do
        template db['template']
        owner db['owner']
        encoding db['encoding']
        locale db['locale']
        host cluster_config["host"]
        port cluster_config["port"]
      end
    end

  end
end

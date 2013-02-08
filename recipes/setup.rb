#
# Cookbook Name:: postgresql
# Recipe:: setup
#
# Copyright 2012, Coroutine LLC
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
# --------------------------------------
# Sample Item from the specified Databag
# --------------------------------------
# {
#    "id": "postgresql_setup_wfp",
#    "users": [
#        {
#            "username":"some_user",
#            "password":"some_password",
#            "superuser": "true",
#        }
#    ],
#    "databases": [
#        {
#            "name":"some_db",
#            "owner":"some_user",
#            "template":"template0",
#            "encoding": "UTF8",
#            "locale": "en_US.utf8"
#        }
#    ]
# }
# --------------------------------------

node["postgresql"]["clusters"].each() do |name, config|

  # Fetch the setup items from the Databag; It contains things like Datase users,
  # passwords, DB names and encoding.
  setup_items = []
  config['setup_items'].each do |itemname|
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

  # We use a mix of psql commands and SQL statements to create users.
  #
  # To Create a User:
  #     sudo -u postgres createuser -s some_user
  #
  # To set their password:
  #     sudo -u postgres psql -c "ALTER USER some_user WITH PASSWORD 'secret';"
  #
  # To create a Database
  #     sudo -u postgres createdb -E UTF8 -O some_user \
  #          -T template0 database_name --local=en_US.utf8
  #
  # To make these idempotent, we test for existing users/databases;
  # Test for existing DB:
  #     sudo -u postgres psql -l | grep database_name
  #
  # Test for existing Users
  #     sudo -u postgres psql -c "\du" | grep some_user

  setup_items.each do |setup|

    setup["users"].each do |user|

      pg_user user['username'] do
        username user['username']
        password user['password']
        superuser user['superuser']
        create_role user['create_role']
        create_db user['create_db']
        encrypted user['encrypted']
        host config["host"]
        port config["port"]
      end
    end

    setup["databases"].each do |db|

      pg_database db['name'] do
        template db['template']
        owner db['owner']
        encoding db['encoding']
        locale db['locale']
        host config["host"]
        port config["port"]
      end
    end

  end
end

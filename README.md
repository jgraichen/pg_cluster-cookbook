Description
===========

Chef cookbook for setup and configure postgresql clusters

Features:

* Clusters creation
* Postgresql installation from apt.postgresql.org
* Users creating
* Replication


Requirements
============

## Platforms

* Debian, Ubuntu

## Cookboooks

* openssl
* apt

Attributes
==========

The following attributes are set based on the platform, see the
`attributes/default.rb` file for default values.

* `node['postgresql']['version']` - version of postgresql to manage
* `node['postgresql']['config_dir']` - directory that store clusters configs
* `node['postgresql']['data_dir']` - directory that store cluster data
* `node['postgresql']['data_run']` - directory of where postgresql pid files and
  socket lives
* `node['postgresql']['log_dir']` - directory of where postgresql locate logfiles


The following attributes are used by the `setup` recipe:
* `node['postgresql']['databag']` - the data bag in which the `setup` recipe
  searches for items. Default is `postgresql`
* `node['postgresql']['setup_items']` - a list of data bag items
  containing user/database information. See the notes for the `setup` recipe
  for the expected format.

There are also a number of other attributes defined that control  things such
as host based access (`pg_hba.conf`) and hot standby. A few are listed below,
but see `attributes/default.rb` for more information.
* `node['postgresql']['hba']` - a default list of `address`/`method` hashes
  defining the ip address that will be able to connect to PostreSQL

Recipes
=======

default
-------

This recipe empty.

server
------------------
Install postgresql client and server packages from node attributes.
Also create and configure clusters from ``node['postgresql']['clusters']``.

setup
-----
Creates Roles (user account) and Databases from a data bag. See the *Usage*
section for more info.


Definitions
===========

This cookbook have 3 definitions:

### pg_cluster

Help to create specified postgresql cluster with full customization.

#### Attributes

- ``name`` - cluster name
- ``version`` - cluster postgresql server version
- ``locale`` - cluster default locale
- ``config`` - cluster configuration variables (``postgresql.conf.erb``
  configuration stored in ``config[:config]`` key)
- ``host`` - cluster host
- ``port`` - port that listen cluster instance

Example:

    # /etc/postgresql/#{node["postgresql"]["version"]}/my_cluster_name/
    pg_cluster "my_cluster_name" do
        version node["postgresql"]["version"]
        locale "ru_RU.UTF-8"
        config {}
        host "localhost"
        port 5434
    end

### pg_user

Create postgresql users in specified postgresql cluster.

#### Attributes

- ``username``
- ``password`` - user password
- ``superuser`` - is user a super? (default: false)
- ``create_role`` - can user create roles? (defautl: false)
- ``create_db`` - can user create databases? (default: false)
- ``encrypted`` - encrypt user password? (default: true)
- ``host`` - cluster host
- ``port`` - cluster port

Example:

    pg_user "username-1" do
        username "username-1"
        password "password"
        superuser false
        create_role false
        create_db true
        encrypted true
        host "/var/run/postgresql"
        port 5433 # cluster port
    end

### pg_database

Create postgresql database in specified postgresql cluster

#### Attributes

- ``template`` - database template name
- ``owner`` - database owner
- ``encoding`` - database encoding
- ``locale`` - database locale
- ``host`` - cluster host
- ``port`` - cluster port

Example:

    pg_database "megadb" do
        template "template1"
        owner "username-1"
        encoding "UTF-8"
        locale "ru_RU.UTF-8"
        host "/var/run/postgresql"
        port 5333 # Cluster port
   end


Resources/Providers
===================

### postgresql

Provider that install specified ``postgresql`` version. To install
from apt.postgresql.org repository
 you can specify ``node['postgresq']['provider']=='postgresql_pg_apt'``

#### Attribute parameters

- ``version`` - required postgresql version
- ``name`` - package name
- ``extra_packages`` - install additional packages (dev, etc..)

#### Providers

This cookbook included 2 providers

- ``Chef::Provider::Postgresql`` - install via platform repository
- ``Chef::Provider::PostgresqlPgapt`` - add official posgtresql ``apt.postgresql.org``
  to system ``sources.d`` and install ``postgresql`` from it.

Usage
=====

On systems that need to connect to a PostgreSQL database, add to a run list
``recipe[postgresql::server]``.

For users and database creation add ``recipe[postgresql::setup]`` after server
installation recipes.

Cluster creation:
    # /etc/postgresql/#{node["postgresql"]["version"]}/my_cluster_name/
    pg_cluster "my_cluster_name" do
        version node["postgresql"]["version"]
        locale "ru_RU.UTF-8"
        config {}
        host "localhost"
        port 5434
    end

User creation:

    pg_user "username-1" do
        username "username-1"
        password "password"
        superuser false
        create_role false
        create_db true
        encrypted true
        host "/var/run/postgresql"
        port 5433 # cluster port
    end

Database creation:

    pg_database "megadb" do
        template "template1"
        owner "username-1"
        encoding "UTF-8"
        locale "ru_RU.UTF-8"
        host "/var/run/postgresql"
        port 5333 # Cluster port
   end


If you include ``recipe[postgresql::server]`` and ``recipe[postgresql::setup``
clusters, users and databases will be created automatical from node cluster attributes.

### Cluster attributes configuration examples

    override_attributes(
                    :postgresql => {
                      #:provider => "postgresql_pg_apt",
                      :version => "8.4", # postgresql version to install
                      :databag => "postgresql", # databag from which items are fetched
                      :clusters => {
                        "main" => {
                          :version => "8.4", # cluster version
                          :port => 5434, # cluster port
                          :hba => [ # main hba configuration
                                   # { :method => 'ident', :address => '', :type => 'local', :user => "postgres"},
                                   { :method => 'md5', :address => '127.0.0.1/32' },
                                   { :method => 'md5', :address => '::1/128' }],
                          :password => {:postgres => "password"}, # cluster postgres user password
                          # Create users and databases in cluster from attributes
                          :setup_items => ["sentry",
                                           "databagname"],
		          :config => { # postgresql.conf configuration variables
			     "listen_addresses" => "*",
			     "ssl" => "true",
			     "shared_buffers" => "24MB"
			  }
                        }
                      },
                      "extra_packages" => ["postgresql-8.4-postgis", "postgresql-contrib-8.4",
                                           "postgresql-doc-8.4", "postgresql-plpython-8.4",
                                           "postgresql-server-dev-8.4"]
    })



### User/Database Setup

To configure users and databases, create a data bag with the name used in the
`default[:postgresql][:databag]` attribute. Items in this databag will be used
to create both PostgreSQL users and databases. The format of each databag item
should be similar to the following:

    {
       "id": "sample_db_setup",
       "users": [
           {
               "username":"some_user",
               "password":"some_password",
               "superuser": "true",
	       "create_role": "false",
	       "create_db": "true"
           }
       ],
       "databases": [
           {
               "name":"some_db",
               "owner":"some_user",
               "template":"template0",
               "encoding": "UTF8",
               "locale": "en_US.utf8"
           }
       ]
    }


Then, override the `node['postgresql']['setup_items']` attribute in a role:

    override_attributes(
      :postgresql => {
        :clusters => {
	  # Cluster configuration here
          :databag     => "postgresql", # databag from which items are fetched
          :setup_items => ["sample_db_setup", ]  # name of item from which
                                                 # user/database info is read.
      }}
    )

License and Author
==================

Author:: Joshua Timberman (<joshua@opscode.com>)
Author:: Lamont Granquist (<lamont@opscode.com>)
Author:: Brad Montgomery (<brad@bradmontgomery.net>)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

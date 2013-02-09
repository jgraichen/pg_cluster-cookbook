#
# Cookbook Name:: postgresql
# Attributes:: postgresql
#
# Copyright 2008-2009, Opscode, Inc.
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


default[:postgresql][:provider] = "postgresql"
default[:postgresql][:version] = "8.4"
default[:postgresql]["extra_packages"] = []


# Host Based Access
default[:postgresql][:hba] = [
  { :method => 'md5', :address => '127.0.0.1/32' },
  { :method => 'md5', :address => '::1/128' }
]

# Role/Database Setup
# -------------------
# list of item names. See README for format of a data bag item
default[:postgresql][:setup_items] = []
default[:postgresql][:databag] = "postgresql" # name of the data bag containing
                                              # setup items.

default[:postgresql]["config_dir"] = "/etc/postgresql"
default[:postgresql]["data_dir"] = "/var/lib/postgresql"
default[:postgresql]["data_run"] = "/var/run/postgresql"
default[:postgresql]["log_dir"] = "/var/log/postgresql"
default[:postgresql]["locale"] = "en_US.UTF-8"
default[:postgresql]["lc"] = {}


default[:postgresql]["config"] = {
  "connection" => {
    "max_connections" => 100,
    "listen_addresses" => "localhost"
  },
  "authentication" => {
#    "ssl" => "true",
#    "ssl_cert_key" => "/etc/ssl/certs/ssl-cert-snakeoil.pem",
#    "ssl_key_file" => "/etc/ssl/private/ssl-cert-snakeoil.key"


  },
  "resource_usage" => {
    "shared_buffers" => "24MB"
  },
  "ahead_log" => {
    #"wal_level" => "minimal",
  },
  "replication" => {
    # "max_wal_senders" => 0,
    # "wal_keep_segments" => 0,
    # "vacuum_defer_cleanup_age" => 0
  },
  "query_tuning" => {},
  "logging" => {
    "log_line_prefix" => "%t ",
    "log_timezone" => "localtime"
  },
  "autovacuum" => {},
  "client_connection" => {
    "datestyle" => "iso, mdy",
    "timezone" => "localtime",
    "lc_messages" => "en_US",
    "lc_monetary" => "en_US",
    "lc_numeric" => "en_US",
    "lc_time" => "en_US",
    "default_text_search_config" => "pg_catalog.english"
  },
  "lock_management" => {},
  "error_handling" => {}
}


default[:postgresql][:postgis][:install] = false

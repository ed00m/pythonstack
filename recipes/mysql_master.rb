#
# Cookbook Name:: pythonstack
# Recipe:: mysql_master
#
# Copyright 2014, Rackspace
#

include_recipe 'chef-sugar'
include_recipe 'pythonstack::mysql_base'

include_recipe 'mysql-multi::mysql_master'

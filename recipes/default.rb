# Encoding: utf-8
#
# Cookbook Name:: pythonstack
# Recipe:: default
#
# Copyright 2014, Rackspace UK, Ltd.
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

# Include the necessary recipes.

case node['platform_family']
when 'debian'
  %w(platformstack::monitors platformstack::iptables apt chef-sugar python).each do |recipe|
    include_recipe recipe
  end
when 'rhel'
  %w(platformstack::monitors platformstack::iptables apt chef-sugar python::package python::pip).each do |recipe|
    include_recipe recipe
  end
  python_pip 'distribute' do
    action :install
    version '0.6.16'
  end
  include_recipe 'python::virtualenv'
end

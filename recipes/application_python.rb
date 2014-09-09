# Encoding: utf-8
#
# Cookbook Name:: pythonstack
# Recipe:: application_python
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

# set up demo if needed
include_recipe 'pythonstack::default'

include_recipe 'build-essential'
include_recipe "pythonstack::#{node['pythonstack']['webserver']}"
include_recipe 'git'
include_recipe 'python::package'
include_recipe 'python::pip'
python_pip 'setuptools' do
  action :upgrade
  version node['python']['setuptools_version']
end

include_recipe 'python'
include_recipe 'mysql::client'

python_pip 'distribute'
if platform_family?('debian')
  package 'python-mysqldb'
end
python_pip 'configparser'
python_pip 'sqlalchemy'
python_pip 'flask'
python_pip 'python-memcached'
python_pip 'gunicorn'
python_pip 'MySQL-python' do
  options '--allow-external' unless platform_family?('rhel')
end
python_pip 'pymongo'

include_recipe 'chef-sugar'

# if gluster is in our environment, install the utils and mount it to /var/www
gluster_cluster = node['rackspace_gluster']['config']['server']['glusters'].values[0]
if gluster_cluster.key?('nodes')
  # get the list of gluster servers and pick one randomly to use as the one we connect to
  gluster_ips = []
  if gluster_cluster['nodes'].respond_to?('each')
    gluster_cluster['nodes'].each do |server|
      gluster_ips.push(server[1]['ip'])
    end
  end
  node.set_unless['pythonstack']['gluster_connect_ip'] = gluster_ips.sample

  # install gluster mount
  package 'glusterfs-client' do
    action :install
  end

  # set up the mountpoint
  mount 'webapp-mountpoint' do
    fstype 'glusterfs'
    device "#{node['pythonstack']['gluster_connect_ip']}:/#{node['rackspace_gluster']['config']['server']['glusters'].values[0]['volume']}"
    mount_point node['apache']['docroot_dir']
    action %w(mount enable)
  end
end

node[node['pythonstack']['webserver']]['sites'].each do | site_name, site_opts |
  application site_name do
    path site_opts['docroot']
    owner node[node['pythonstack']['webserver']]['user']
    group node[node['pythonstack']['webserver']]['group']
    deploy_key site_opts['deploy_key']
    repository site_opts['repository']
    revision site_opts['revision']
    restart_command "if [ -f /var/run/uwsgi-#{site_name}.pid ] && ps -p `cat /var/run/uwsgi-         #{site_name}.pid` >/dev/null;
    then kill `cat /var/run/uwsgi-#{site_name}.pid`; fi" if node['pythonstack']['webserver'] == 'nginx'
  end
end

if Chef::Config[:solo]
  Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
  mysql_node = nil
  rabbit_node = nil
else
  mysql_node = search('node', "recipes:pythonstack\\:\\:mysql_master AND chef_environment:#{node.chef_environment}").first
  rabbit_node = search('node', "recipes:pythonstack\\:\\:rabbitmq AND chef_environment:#{node.chef_environment}").first
end
template 'pythonstack.ini' do
  path '/etc/pythonstack.ini'
  cookbook node['pythonstack']['ini']['cookbook']
  source 'pythonstack.ini.erb'
  owner 'root'
  group node[node['pythonstack']['webserver']]['group']
  mode '00640'
  variables(
    cookbook_name: cookbook_name,
    # if it responds then we will create the config section in the ini file
    mysql: if mysql_node.respond_to?('deep_fetch')
             if mysql_node.deep_fetch(node['pythonstack']['webserver'], 'sites').nil?
               nil
             else
               mysql_node.deep_fetch(node['pythonstack']['webserver'], 'sites').values[0]['mysql_password'].nil? ? nil : mysql_node
             end
           end,
    rabbit_host: if rabbit_node.respond_to?('deep_fetch')
                   best_ip_for(rabbit_node)
                 else
                   nil
                 end,
    rabbit_passwords: if rabbit_node.respond_to?('deep_fetch')
                        rabbit_node.deep_fetch('pythonstack', 'rabbitmq', 'passwords').values[0].nil? == true ? nil : rabbit_node['pythonstack']['rabbitmq']['passwords']
                      else
                        nil
                      end
  )
  action 'create'
  # For Nginx the service Uwsgi subscribes to the template, as we need to restart each Uwsgi service
  notifies 'restart', 'service[apache2]', 'delayed' unless node['pythonstack']['webserver'] == 'nginx'
end

# backups
node.default['rackspace']['datacenter'] = node['rackspace']['region']
node.set_unless['rackspace_cloudbackup']['backups_defaults']['cloud_notify_email'] = 'example@example.com'
# we will want to change this when https://github.com/rackspace-cookbooks/rackspace_cloudbackup/issues/17 is fixed
node.default['rackspace_cloudbackup']['backups'] =
  [
    {
      location: node[node['pythonstack']['webserver']]['docroot_dir'],
      enable: node['pythonstack']['rackspace_cloudbackup']['http_docroot']['enable'],
      comment: 'Web Content Backup',
      cloud: { notify_email: node['rackspace_cloudbackup']['backups_defaults']['cloud_notify_email'] }
    }
  ]

tag('python_app_node')

# Encoding: utf-8
name 'pythonstack'
maintainer 'Rackspace'
maintainer_email 'rackspace-cookbooks@rackspace.com'
license 'Apache 2.0'
description 'Installs/Configures pythonstack'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.4.7'

depends 'apache2'
depends 'application'
depends 'application_python'
depends 'apt'
depends 'build-essential'
depends 'chef-sugar'
depends 'database'
depends 'git'
depends 'graylog'
depends 'memcached'
depends 'mysql'
depends 'mysql-multi'
depends 'newrelic'
depends 'pg-multi'
depends 'platformstack'
depends 'python'
depends 'rabbitmq'
depends 'redis-multi'
depends 'varnish'
depends 'yum'
depends 'yum-epel'
depends 'yum-ius'

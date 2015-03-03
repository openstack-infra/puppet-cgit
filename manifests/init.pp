# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Class: cgit
#
class cgit(
  $vhost_name = $::fqdn,
  $serveradmin = "webmaster@${::fqdn}",
  $serveraliases = '',
  $cgitdir = '/var/www/cgit',
  $staticfiles = '/var/www/cgit/static',
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $behind_proxy = false,
  $git_timeout = false,
) {

  if $behind_proxy == true {
    $http_port = 8080
    $https_port = 4443
    $daemon_port = 29418
  }
  else {
    $http_port = 80
    $https_port = 443
    $daemon_port = 9418
  }

  include apache

  if ($::osfamily == 'RedHat') {
    include cgit::selinux
  }

  package { [
      'cgit',
      'git-daemon',
      'highlight',
    ]:
    ensure => present,
  }

  user { 'cgit':
    ensure     => present,
    home       => '/home/cgit',
    shell      => '/bin/bash',
    gid        => 'cgit',
    managehome => true,
    require    => Group['cgit'],
  }

  group { 'cgit':
    ensure => present,
  }

  file {'/home/cgit':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0755',
    require => User['cgit'],
  }

  file { '/var/lib/git':
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0644',
    require => User['cgit'],
  }

  apache::vhost { $vhost_name:
    port          => $https_port,
    serveraliases => $serveraliases,
    git_timeout   => $git_timeout,
    docroot       => 'MEANINGLESS ARGUMENT',
    priority      => '50',
    template      => 'cgit/git.vhost.erb',
    ssl           => true,
    require       => [
      File[$staticfiles],
      Package['cgit'],
    ],
  }

  file { '/etc/httpd/conf/httpd.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('cgit/httpd.conf.erb'),
    require => Package['httpd'],
  }

  file { '/etc/httpd/conf.d/ssl.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('cgit/ssl.conf.erb'),
    require => Package[$::apache::params::ssl_package],
  }

  file { $cgitdir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { $staticfiles:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$cgitdir],
  }

  file { '/etc/init.d/git-daemon':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('cgit/git-daemon.init.erb'),
  }

  service { 'git-daemon':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/init.d/git-daemon'],
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_key_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }
}

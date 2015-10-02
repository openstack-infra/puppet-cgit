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
  $serveraliases = undef,
  $cgitdir = '/var/www/cgit',
  $staticfiles = '/var/www/cgit/static',
  $ssl_cert_file = undef,
  $ssl_key_file = undef,
  $ssl_chain_file = undef,
  $ssl_cert_file_contents = undef, # If left undefined puppet will not create file.
  $ssl_key_file_contents = undef, # If left undefined puppet will not create file.
  $ssl_chain_file_contents = undef, # If left undefined puppet will not create file.
  $behind_proxy = false,
  $cgit_timeout = false,
  $manage_cgitrc = false,
  $prefork_settings = {}, # override the prefork worker settings
  $mpm_settings = {}, # override the mpm worker settings
  $cgitrc_settings = {},
  $selinux_mode = 'enforcing'
) {
  validate_hash($prefork_settings)
  validate_hash($mpm_settings)
  $default_prefork_settings = {
    'StartServers'        => 8,
    'MinSpareServers'     => 5,
    'MaxSpareServers'     => 20,
    'ServerLimit'         => 256,
    'MaxClients'          => 256,
    'MaxRequestsPerChild' => 4000
  }
  $default_mpm_settings = {
    'StartServers'        => 4,
    'MaxClients'          => 300,
    'MinSpareThreads'     => 25,
    'MaxSpareThreads'     => 75,
    'ThreadsPerChild'     => 25,
    'MaxRequestsPerChild' => 0
  }
  $default_cgitrc_settings = {
    'cache-size'          => 1000,
    'cache-dynamic-ttl'   => 1,
    'cache-repo-ttl'      => 1,
    'cache-root-ttl'      => 1,
    'clone-prefix'        => "git://${::fqdn} https://${::fqdn}",
    'enable-index-owner'  => 0,
    'enable-index-links'  => 1,
    'enable-http-clone'   => 0,
    'max-stats'           => 'quarter',
    'side-by-side-diffs'  => 1,
    'mimetype.gif'        => 'image/gif',
    'mimetype.html'       => 'text/html',
    'mimetype.jpg'        => 'image/jpeg',
    'mimetype.jpeg'       => 'image/jpeg',
    'mimetype.pdf'        => 'application/pdf',
    'mimetype.png'        => 'image/png',
    'mimetype.svg'        => 'image/svg+xml',
    'source-filter'       => '/usr/libexec/cgit/filters/syntax-highlighting.sh',
    'max-repo-count'      => 600,
    'include'             => '/etc/cgitrepos'
  }
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

  # merge settings with defaults
  $final_mpm_settings = merge($default_mpm_settings, $mpm_settings)
  $final_prefork_settings = merge($default_prefork_settings, $prefork_settings)
  $final_cgitrc_settings = merge($default_cgitrc_settings, $cgitrc_settings)

  include ::httpd

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

  $local_git_dir = '/var/lib/git'

  file { $local_git_dir:
    ensure  => directory,
    owner   => 'cgit',
    group   => 'cgit',
    mode    => '0644',
    require => User['cgit'],
  }

  file { "${local_git_dir}/p":
    ensure  => link,
    target  => $local_git_dir,
    require => File[$local_git_dir],
  }

  ::httpd::vhost { $vhost_name:
    port          => $https_port,
    serveraliases => $serveraliases,
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
    notify  => Service['httpd'],
  }

  file { '/etc/httpd/conf.d/ssl.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('cgit/ssl.conf.erb'),
    require => Class['::httpd::ssl'],
    notify  => Service['httpd'],
  }

  if ($::osfamily == 'Debian') {
    # httpd_mod is not supported on Centos and mod_version is installed
    # by default there so this is not necessary unless on Debian.
    httpd_mod { 'version':
      ensure => present,
    }
  }

  if ($::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7') {
    package { 'mod_ldap':
      ensure => present,
    }
  }

  file { $cgitdir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['httpd']
  }

  file { $staticfiles:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File[$cgitdir],
  }

  if ($::osfamily == 'RedHat' and $::operatingsystemmajrelease >= '7') {
    $git_daemon_service_name = 'git-daemon.socket'
    file { '/usr/lib/systemd/system/git-daemon.socket':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('cgit/git-daemon.socket.erb'),
    }
    file { 'git-daemon-init-script':
      ensure  => present,
      path    => '/usr/lib/systemd/system/git-daemon@.service',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/cgit/git-daemon.service',
      require => File['/usr/lib/systemd/system/git-daemon.socket'],
    }
  } else {
    $git_daemon_service_name = 'git-daemon'
    file { 'git-daemon-init-script':
      ensure  => present,
      path    => '/etc/init.d/git-daemon',
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('cgit/git-daemon.init.erb'),
    }
  }

  service { $git_daemon_service_name:
    ensure    => running,
    enable    => true,
    subscribe => File['git-daemon-init-script'],
  }

  if ($::osfamily == 'RedHat') {
    case $selinux_mode {
      'disabled': {
        warning('Running with selinux "disabled" is not recommended')
      }
      default: {
        include ::cgit::selinux
      }
    }
  }

  if $ssl_cert_file_contents != undef {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != undef {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_key_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != undef {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }
  if $manage_cgitrc {
    file { '/etc/cgitrc':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('cgit/cgitrc.erb')
    }
  }

}

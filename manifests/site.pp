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
define cgit::site(
  $behind_proxy            = false,
  $cgit_timeout            = false,
  $cgitdir                 = '/var/www/cgit',
  $cgitrc_path             = '/etc/cgitrc',
  $cgitrc_settings         = {},
  $manage_cgitrc           = false,
  $selinux_mode            = 'enforcing',
  $serveradmin             = "webmaster@${::fqdn}",
  $serveraliases           = undef,
  $ssl_cert_file           = undef,
  $ssl_cert_file_contents  = undef, # If left undefined puppet will not create file.
  $ssl_chain_file          = undef,
  $ssl_chain_file_contents = undef, # If left undefined puppet will not create file.
  $ssl_key_file            = undef,
  $ssl_key_file_contents   = undef, # If left undefined puppet will not create file.
  $staticfiles             = '/var/www/cgit/static',
  $local_git_dir           = '/var/lib/git',
  $cgit_vhost_name         = $::fqdn,
  $cgit_vhost_priority     = '50',
) {
  $default_cgitrc_settings = {
    'cache-size'          => 1000,
    'cache-dynamic-ttl'   => 1,
    'cache-repo-ttl'      => 1,
    'cache-root-ttl'      => 1,
    'cache-root'          => "/var/cache/cgit/${cgit_vhost_name}",
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
  } else {
    $http_port = 80
    $https_port = 443
    $daemon_port = 9418
  }

  # merge settings with defaults
  $final_cgitrc_settings = merge($default_cgitrc_settings, $cgitrc_settings)

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

  exec { "restorecon -R -v ${local_git_dir}":
    path        => '/sbin',
    require     => File[$local_git_dir],
    subscribe   => File[$local_git_dir],
    refreshonly => true,
  }

  ::httpd::vhost { $cgit_vhost_name:
    port          => $https_port,
    serveraliases => $serveraliases,
    docroot       => 'MEANINGLESS ARGUMENT',
    priority      => $cgit_vhost_priority,
    template      => 'cgit/git.vhost.erb',
    ssl           => true,
    require       => [
      File[$staticfiles],
      Package['cgit'],
    ],
  }

  file { "/var/cache/cgit/${cgit_vhost_name}":
    ensure  => directory,
    owner   => 'apache',
    group   => 'root',
    mode    => '0755',
    require => Package['cgit']
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


  if $ssl_cert_file_contents != undef {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Httpd::Vhost[$cgit_vhost_name],
    }
  }

  if $ssl_key_file_contents != undef {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_key_file_contents,
      before  => Httpd::Vhost[$cgit_vhost_name],
    }
  }

  if $ssl_chain_file_contents != undef {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Httpd::Vhost[$cgit_vhost_name],
    }
  }
  if $manage_cgitrc {
    file { $cgitrc_path:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('cgit/cgitrc.erb')
    }
  }
}

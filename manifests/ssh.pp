# Copyright 2014 Hewlett-Packard Development Company, L.P.
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
# Class: cgit::ssh
#
class cgit::ssh (
  $user = 'git',
  $group = 'git',
  $manage_group = true,
  $home = '/var/lib/git',
  $manage_home = true,
  $target = undef,
  $target_name = 'repo',
  $push = false,
  $authorized_keys = [],
) {

  if ($manage_home) and (! defined(File[$home])) {
    file { $home:
      ensure  => directory,
      owner   => $user,
      group   => $group,
      mode    => '0755',
      require => User[$user],
    }
  }

  if $target != undef {
  # This should be a directory that contains bare repos
    file { "${home}/${target_name}":
      ensure  => link,
      target  => $target,
      require => File[$home],
    }
  }

  if ($manage_group) and (! defined(Group[$group])) {
    group { $group:
      ensure => present,
    }
  }

  user { $user:
    ensure     => present,
    shell      => '/usr/bin/git-shell',
    gid        => $group,
    home       => $home,
    managehome => true,
    require    => Group[$group],
  }

  $ssh_dir = "${home}/.ssh"
  file { $ssh_dir:
    ensure => directory,
    owner  => $user,
    mode   => '0750',
  }

  $auth_file = "${ssh_dir}/authorized_keys"
  file { $auth_file:
    ensure  => present,
    owner   => $user,
    mode    => '0640',
    content => template('cgit/authorized_keys.erb'),
    require => [
      File[$ssh_dir],
      User[$user],
    ],
  }
}

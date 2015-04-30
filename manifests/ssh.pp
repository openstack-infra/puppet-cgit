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
# This class enables clones from git repo using ssh protocol
#
# params:
#   user:
#     The user that will be used for git clone
#   group:
#     The group for the git user
#   manage_group:
#     If enabled, it will create the group for the git user
#   home:
#     The home directory of the git user
#   manage_home:
#     If enabled, it wil manage the home directory for the git user
#   target:
#     If set, it creates a symlink for the git directory
#   target_name:
#     If target is set, it defined the name of the source git directory
#   authorized_keys
#     Array with the list of keys that will be used for authorizing git
#     clones over ssh
class cgit::ssh (
  $user = 'git',
  $group = 'git',
  $manage_group = true,
  $home = '/var/lib/git',
  $manage_home = true,
  $target = undef,
  $target_name = 'repo',
  $authorized_keys = [],
) {

  if $manage_home {
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

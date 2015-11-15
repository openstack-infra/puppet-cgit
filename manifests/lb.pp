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
# Class: cgit::lb
#
class cgit::lb (
  $balancer_member_names = [],
  $balancer_member_ips = [],
  $balancer_member_http_ports = ['8080',],
  $balancer_member_https_ports = ['4443',],
  $balancer_member_git_ports = ['29418',],
  $global_options = {
    'log'     => '127.0.0.1 local0',
    'chroot'  => '/var/lib/haproxy',
    'pidfile' => '/var/run/haproxy.pid',
    'maxconn' => '4000',
    'user'    => 'haproxy',
    'group'   => 'haproxy',
    'daemon'  => '',
    'stats'   => 'socket /var/lib/haproxy/stats user root group root mode 0600 level admin'
  },
  $defaults_options = {
    'log'     => 'global',
    'stats'   => 'enable',
    'option'  => 'redispatch',
    'retries' => '3',
    'timeout' => [
      'http-request 10s',
      'queue 1m',
      'connect 10s',
      'client 2m',
      'server 2m',
      'check 10s',
    ],
    'maxconn' => '8000',
  },
  $http_options = {
    'balance' => 'leastconn',
    'option'  => [
      'tcplog',
    ],
  },
  $https_options = {
    'balance' => 'leastconn',
    'option'  => [
      'tcplog',
    ],
  },
  $git_options = {
    'maxconn' => '256',
    'backlog' => '256',
    'balance' => 'leastconn',
    'option'  => [
      'tcplog',
    ],
  },
) {

  package { 'socat':
    ensure => present,
  }

  package { 'lsof':
    ensure => present,
  }

  class { '::haproxy':
    enable           => true,
    global_options   => $global_options,
    defaults_options => $defaults_options,
  }

  # The three listen defines here are what the world will hit.
  $haproxy_addresses = delete_undef_values([$::ipaddress, $::ipaddress6])

  haproxy::listen { 'balance_git_http':
    ipaddress        => $haproxy_addresses,
    ports            => ['80'],
    mode             => 'tcp',
    collect_exported => false,
    options          => $http_options,
  }
  haproxy::listen { 'balance_git_https':
    ipaddress        => $haproxy_addresses,
    ports            => ['443'],
    mode             => 'tcp',
    collect_exported => false,
    options          => $https_options,
  }
  haproxy::listen { 'balance_git_daemon':
    ipaddress        => $haproxy_addresses,
    ports            => ['9418'],
    mode             => 'tcp',
    collect_exported => false,
    options          => $git_options,
  }
  haproxy::balancermember { 'balance_git_http_member':
    listening_service => 'balance_git_http',
    server_names      => $balancer_member_names,
    ipaddresses       => $balancer_member_ips,
    ports             => $balancer_member_http_ports,
  }
  haproxy::balancermember { 'balance_git_https_member':
    listening_service => 'balance_git_https',
    server_names      => $balancer_member_names,
    ipaddresses       => $balancer_member_ips,
    ports             => $balancer_member_https_ports,
  }
  haproxy::balancermember { 'balance_git_daemon_member':
    listening_service => 'balance_git_daemon',
    server_names      => $balancer_member_names,
    ipaddresses       => $balancer_member_ips,
    ports             => $balancer_member_git_ports,
    options           => 'maxqueue 512',
  }

  if (!defined(Service['rsyslog'])) {
    service { 'rsyslog':
      ensure => running,
      enable => true,
    }
  }

  file { '/etc/rsyslog.d/haproxy.conf':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/cgit/rsyslog.haproxy.conf',
    notify => Service['rsyslog'],
  }
}

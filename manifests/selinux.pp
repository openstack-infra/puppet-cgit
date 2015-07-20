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
# Class: cgit::selinux
#
class cgit::selinux {
  exec { 'restorecon -R -v /var/lib/git':
    path        => '/sbin',
    require     => File['/var/lib/git'],
    subscribe   => File['/var/lib/git'],
    refreshonly => true,
  }

  selboolean { 'httpd_enable_cgi':
    persistent => true,
    value      => on
  }

  exec { 'cgit_allow_http_port':
    # If we cannot add the rule modify the existing rule.
    unless      => "semanage port -l | grep \'http_port_t.*tcp.*${::cgit::http_port}\'",
    command     => "semanage port -a -t http_port_t -p tcp ${::cgit::http_port} \
                    || semanage port -m -t http_port_t -p tcp ${::cgit::http_port}",
    path        => '/bin:/usr/sbin',
    before      => Service['httpd'],
    subscribe   => File['/etc/httpd/conf/httpd.conf'],
  }

  exec { 'cgit_allow_https_port':
    # If we cannot add the rule modify the existing rule.
    unless      => "semanage port -l | grep \'http_port_t.*tcp.*${::cgit::https_port}\'",
    command     => "semanage port -a -t http_port_t -p tcp ${::cgit::https_port} \
                    || semanage port -m -t http_port_t -p tcp ${::cgit::https_port}",
    path        => '/bin:/usr/sbin',
    subscribe   => File['/etc/httpd/conf.d/ssl.conf'],
  }
}


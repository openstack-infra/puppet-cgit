if ($::osfamily == 'Debian') {
  class { '::cgit::lb':
    balancer_member_names => [ 'local' ],
    balancer_member_ips   => [ '127.0.0.1' ],
  }
}

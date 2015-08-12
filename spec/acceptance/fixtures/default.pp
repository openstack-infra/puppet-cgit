if $::osfamily == 'RedHat' {
  package { 'policycoreutils-python':
    ensure => present,
  }
}
class { '::cgit':
  ssl_cert_file => '/etc/pki/tls/certs/dummy.crt',
  ssl_key_file  => '/etc/pki/tls/private/dummy.key',
}

# Installing ssl-cert in order to get snakeoil certs
if ($::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7') {
  exec { 'creates self-signed certificate directory':
    path    => '/usr/bin',
    command => 'mkdir -p /etc/ssl/certs',
    creates => '/etc/ssl/certs',
  }

  exec { 'creates self-signed certificate key directory':
    path    => '/usr/bin',
    command => 'mkdir -p /etc/ssl/private',
    creates => '/etc/ssl/private',
  }

  exec { 'creates self-signed certificate':
    path    => '/usr/bin',
    command => 'openssl req \
                        -new \
                        -newkey rsa:2048 \
                        -days 365 \
                        -nodes \
                        -x509 \
                        -subj "/C=US/ST=California/L=San Francisco/O=Dis/CN=localhost" \
                        -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
                        -out /etc/ssl/certs/ssl-cert-snakeoil.pem',
    creates => ['/etc/ssl/private/ssl-cert-snakeoil.key', '/etc/ssl/certs/ssl-cert-snakeoil.pem'],
    require => [
      Exec['creates self-signed certificate directory'],
      Exec['creates self-signed certificate key directory'],
    ],
  }

  package { 'policycoreutils-python':
    ensure => present,
  }
}
elsif ($::osfamily == 'Debian') {
  package { 'ssl-cert':
    ensure => present,
  }
}

if ($::osfamily == 'RedHat') {
  exec { 'reload systemd to have ports updated':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => File['/usr/lib/systemd/system/git-daemon.socket'],
  }

  class { '::cgit':
    vhost_name             => 'localhost',
    serveradmin            => 'webmaster@localhost',
    ssl_cert_file_contents => file('/etc/ssl/certs/ssl-cert-snakeoil.pem'),
    ssl_cert_file          => '/etc/pki/tls/certs/localhost.pem',
    ssl_key_file_contents  => file('/etc/ssl/private/ssl-cert-snakeoil.key'),
    ssl_key_file           => '/etc/pki/tls/private/localhost.key',
    manage_cgitrc          => true,
    cgitrc_settings        => {
      'clone-prefix' => 'git://git.openstack.org https://git.openstack.org',
      'root-title'   => 'OpenStack git repository browser',
    },
  }

  class { '::cgit::ssh':
    manage_home     => false,
    require         => Class['::cgit'],
    authorized_keys => [
      'ssh-key 1a2b3c4d5e',
    ],
  }
}

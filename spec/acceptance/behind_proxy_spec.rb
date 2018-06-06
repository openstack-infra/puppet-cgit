require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'puppet-cgit module begind proxy', :if => ['fedora', 'redhat'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def preconditions_puppet_module
    module_path = File.join(pp_path, 'preconditions.pp')
    File.read(module_path)
  end

  def behindproxy_puppet_module
    module_path = File.join(pp_path, 'behindproxy.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  it 'should work with no errors' do
    apply_manifest(behindproxy_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(behindproxy_puppet_module, catch_changes: true)
  end

  describe 'required services' do
    describe 'running web server' do
      describe command('curl http://localhost:8080/cgit') do
        its(:stdout) { should include 'OpenStack git repository browser' }
      end

      describe command('curl --insecure https://localhost:4443/cgit') do
        its(:stdout) { should include 'OpenStack git repository browser' }
      end

      describe port(8080) do
        it { should be_listening }
      end

      describe port(4443) do
        it { should be_listening }
      end

      describe port(29418) do
        it { should be_listening }
      end

      describe service('httpd') do
        it { should be_enabled }
        it { should be_running }
      end
    end

    describe service('git-daemon.socket'), :if => ['fedora', 'redhat'].include?(os[:family]) && os[:release] >= '7' do
      it { should be_enabled }
      it { should be_running }
    end

    describe service('git-daemon'), :if => ['fedora', 'redhat'].include?(os[:family]) && os[:release] < '7' do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe 'required users and groups' do
    describe user('cgit') do
      it { should exist }
      it { should belong_to_group 'cgit' }
    end

    describe group('cgit') do
      it { should exist }
    end

    describe user('git') do
      it { should exist }
      it { should belong_to_group 'git' }
    end

    describe group('git') do
      it { should exist }
    end
  end

  describe 'required os packages' do
    required_packages = [
      package('mod_ldap'),
      package('cgit'),
      package('git-daemon'),
      package('highlight'),
    ]

    required_packages.each do |package|
      describe package do
        it { should be_installed }
      end
    end
  end

  describe 'required files' do
    required_directories = [
      file('/home/cgit'),
      file('/var/lib/git'),
    ]

    required_directories.each do |directory|
      describe directory do
        it { should be_directory }
        it { should be_owned_by 'cgit' }
        it { should be_grouped_into 'cgit' }
      end
    end

    required_directories = [
      file('/var/www/cgit'),
      file('/var/www/cgit/static'),
    ]

    required_directories.each do |directory|
      describe directory do
        it { should be_directory }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end
    end

    describe file('/usr/lib/systemd/system/git-daemon.socket'), :if => ['fedora', 'redhat'].include?(os[:family]) && os[:release] >= '7' do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include 'ListenStream=29418' }
    end

    describe file('/usr/lib/systemd/system/git-daemon@.service'), :if => ['fedora', 'redhat'].include?(os[:family]) && os[:release] >= '7' do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include 'Wants=git-daemon.socket' }
    end

    describe file('/etc/init.d/git-daemon'), :if => ['fedora', 'redhat'].include?(os[:family]) && os[:release] < '7' do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include 'DAEMON=/usr/libexec/git-core/git-daemon' }
      its(:content) { should include 'PORT=29418' }
    end

    describe file('/etc/pki/tls/certs/localhost.pem') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end

    describe file('/etc/pki/tls/private/localhost.key') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end

    describe file('/etc/cgitrc') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include 'clone-prefix=git://git.openstack.org https://git.openstack.org' }
    end

    describe file('/var/lib/git/.ssh/authorized_keys') do
      it { should be_file }
      it { should be_owned_by 'git' }
      it { should be_mode '640' } # Authorized keys file should have a restrict permission
      its(:content) { should include 'ssh-key 1a2b3c4d5e' }
    end

    describe file('/etc/httpd/conf/httpd.conf') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include 'Listen 8080' }
    end

    describe file('/etc/httpd/conf.d/ssl.conf') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include 'Listen 4443' }
    end

    vhost_content = '<VirtualHost *:8080>
  ServerName localhost
  ServerAdmin webmaster@localhost


  Alias /cgit-data /usr/share/cgit
  ScriptAlias /cgit /var/www/cgi-bin/cgit
  Alias /static /var/www/cgit/static
  RewriteEngine On
  RewriteRule ^/$ /cgit [R]

  SetEnv GIT_PROJECT_ROOT /var/lib/git
  SetEnv GIT_HTTP_EXPORT_ALL
  SetEnv GIT_NOTES_DISPLAY_REF refs/notes/*
  SetEnv CGIT_CONFIG /etc/cgitrc

  AliasMatch ^/(.*/objects/[0-9a-f]{2}/[0-9a-f]{38})$ /var/lib/git/$1
  AliasMatch ^/(.*/objects/pack/pack-[0-9a-f]{40}.(pack|idx))$ /var/lib/git/$1
  ScriptAlias / /usr/libexec/git-core/git-http-backend/

  ErrorLog /var/log/httpd/localhost-error.log

  

  LogLevel warn

  CustomLog /var/log/httpd/localhost-access.log combined
</VirtualHost>

<VirtualHost *:4443>
  ServerName localhost
  ServerAdmin webmaster@localhost


  Alias /cgit-data /usr/share/cgit
  ScriptAlias /cgit /var/www/cgi-bin/cgit
  Alias /static /var/www/cgit/static
  RewriteEngine On
  RewriteRule ^/$ /cgit [R]

  SetEnv GIT_PROJECT_ROOT /var/lib/git
  SetEnv GIT_HTTP_EXPORT_ALL
  SetEnv GIT_NOTES_DISPLAY_REF refs/notes/*
  SetEnv CGIT_CONFIG /etc/cgitrc

  AliasMatch ^/(.*/objects/[0-9a-f]{2}/[0-9a-f]{38})$  /var/lib/git/$1
  AliasMatch ^/(.*/objects/pack/pack-[0-9a-f]{40}.(pack|idx))$ /var/lib/git/$1
  ScriptAlias / /usr/libexec/git-core/git-http-backend/

  ErrorLog /var/log/httpd/localhost-ssl-error.log

  LogLevel warn

  CustomLog /var/log/httpd/localhost-ssl-access.log combined

  SSLEngine on
  SSLProtocol All -SSLv2 -SSLv3

  SSLCertificateFile      /etc/pki/tls/certs/localhost.pem
  SSLCertificateKeyFile   /etc/pki/tls/private/localhost.key

</VirtualHost>
'
    describe file('/etc/httpd/conf.d/50-localhost.conf') do
      its(:content) { should eq vhost_content }
    end
  end

  describe 'selinux' do
    describe command("semanage port -l | grep '^http_port_t'") do
      its(:stdout) { should match(/^http_port_t.*\b8080/) }
      its(:stdout) { should match(/^http_port_t.*\b4443/) }
    end

    describe command("semanage port -l | grep '^git_port_t'") do
      its(:stdout) { should match(/^git_port_t.*\b29418/) }
    end
  end
end

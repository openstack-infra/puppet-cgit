require 'spec_helper_acceptance'

describe 'required files', :if => ['fedora', 'redhat'].include?(os[:family]) do
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

  describe file('/usr/lib/systemd/system/git-daemon.socket') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { should match 'ListenStream=9418' }
  end

  describe file('/usr/lib/systemd/system/git-daemon@.service') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { should match 'Wants=git-daemon.socket' }
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
    its(:content) { should match 'clone-prefix=git://git.openstack.org https://git.openstack.org' }
  end

  describe file('/var/lib/git/.ssh/authorized_keys') do
    it { should be_file }
    it { should be_owned_by 'git' }
    it { should be_mode '640' } # Authorized keys file should have a restrict permission
    its(:content) { should match 'ssh-key 1a2b3c4d5e' }
  end

  describe file('/etc/httpd/conf.d/httpd.conf') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { should match 'Listen 80' }
  end

  describe file('/etc/httpd/conf.d/ssl.conf') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { should match 'Listen 443' }
  end
end

describe 'required files', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  describe file('/etc/rsyslog.d/haproxy.conf') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { should match 'local0.*  /var/log/haproxy.log' }
  end
end

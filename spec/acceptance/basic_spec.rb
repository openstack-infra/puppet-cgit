require 'spec_helper_acceptance'

describe 'puppet-cgit module', :if => ['fedora', 'redhat'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def preconditions_puppet_module
    module_path = File.join(pp_path, 'preconditions.pp')
    File.read(module_path)
  end

  def default_puppet_module
    module_path = File.join(pp_path, 'default.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  it 'should work with no errors' do
    apply_manifest(default_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(default_puppet_module, catch_changes: true)
  end

  describe 'cgit server' do
    describe 'running web server' do
      describe command('curl http://localhost/cgit') do
        its(:stdout) { should include 'OpenStack git repository browser' }
      end

      describe command('curl --insecure https://localhost/cgit') do
        its(:stdout) { should include 'OpenStack git repository browser' }
      end

      describe port(80) do
        it { should be_listening }
      end

      describe port(443) do
        it { should be_listening }
      end

      describe port(9418) do
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

    describe file('/var/lib/git/p') do
      it { should be_linked_to '/var/lib/git' }
    end

    describe file('/usr/lib/systemd/system/git-daemon.socket'), :if => ['fedora', 'redhat'].include?(os[:family]) && os[:release] >= '7' do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include 'ListenStream=9418' }
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
      its(:content) { should include 'PORT=9418' }
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
      its(:content) { should include 'Listen 80' }
    end

    describe file('/etc/httpd/conf.d/ssl.conf') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include 'Listen 443' }
    end
  end

  describe 'selinux' do
    describe command("semanage boolean -l | grep '^httpd_enable_cgi'") do
      its(:stdout) { should match(/^httpd_enable_cgi.*\(on   ,   on\)/) }
    end

    describe command("semanage port -l | grep '^http_port_t'") do
      its (:stdout) { should match(/^http_port_t.*\b80/) }
      its (:stdout) { should match(/^http_port_t.*\b443/) }
    end

    describe command("semanage port -l | grep '^git_port_t'") do
      its(:stdout) { should match(/^git_port_t.*\b9418/) }
    end
  end
end

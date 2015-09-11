require 'spec_helper_acceptance'

describe 'cgit server', :if => ['fedora', 'redhat'].include?(os[:family]) do
  describe 'running web server' do
    describe command('curl http://localhost/cgit') do
      its(:stdout) { should match 'OpenStack git repository browser' }
    end

    describe command('curl --insecure https://localhost/cgit') do
      its(:stdout) { should match 'OpenStack git repository browser' }
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

  describe service('git-daemon.socket'), :if => os[:release] >= '7' do
    it { should be_enabled }
    it { should be_running }
  end

  describe service('git-daemon'), :if => os[:release] < '7' do
    it { should be_enabled }
    it { should be_running }
  end
end

describe 'cgit server behind proxy', :if => ['fedora', 'redhat'].include?(os[:family]) do
  before(:all) do
    behind_proxy_manifest = File.join(File.dirname(__FILE__), 'fixtures', 'behindproxy.pp')
    apply_manifest(File.read(behind_proxy_manifest), catch_failures: true)
  end

  describe 'running web server' do
    describe command('curl http://localhost:8080/cgit') do
      its(:stdout) { should match 'OpenStack git repository browser' }
    end

    describe command('curl --insecure https://localhost:4443/cgit') do
      its(:stdout) { should match 'OpenStack git repository browser' }
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

  describe service('git-daemon.socket'), :if => os[:release] >= '7' do
    it { should be_enabled }
    it { should be_running }
  end

  describe service('git-daemon'), :if => os[:release] < '7' do
    it { should be_enabled }
    it { should be_running }
  end
end

describe 'cgit loadbalancer', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  describe port(80) do
    it { should be_listening }
  end

  describe port(443) do
    it { should be_listening }
  end

  describe port(9418) do
    it { should be_listening }
  end

  describe service('haproxy') do
    it { should be_enabled }
    it { should be_running }
  end
end

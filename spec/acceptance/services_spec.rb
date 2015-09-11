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

  describe service('git-daemon.socket') do
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

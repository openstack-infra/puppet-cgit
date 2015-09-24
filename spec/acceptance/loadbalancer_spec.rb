require 'spec_helper_acceptance'

describe 'puppet-cgit loadbalancer module', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def preconditions_puppet_module
    module_path = File.join(pp_path, 'preconditions.pp')
    File.read(module_path)
  end

  def loadbalancer_puppet_module
    module_path = File.join(pp_path, 'loadbalancer.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  it 'should work with no errors' do
    apply_manifest(loadbalancer_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(loadbalancer_puppet_module, catch_changes: true)
  end

  describe 'required services' do
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

  describe 'required os packages' do
    required_packages = [
      package('socat'),
      package('lsof'),
    ]

    required_packages.each do |package|
      describe package do
        it { should be_installed }
      end
    end
  end

  describe 'required files' do
    describe file('/etc/rsyslog.d/haproxy.conf') do
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include 'local0.*  /var/log/haproxy.log' }
    end
  end
end

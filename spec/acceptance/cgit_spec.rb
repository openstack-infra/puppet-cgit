require 'spec_helper_acceptance'

describe 'cgit class' do

  before :all do
    # Generate unmanaged self-signed SSL certs for minimal deployment
    shell('openssl genrsa  -out /etc/pki/tls/private/dummy.key 2048')
    shell('openssl req -new -x509 -key /etc/pki/tls/private/dummy.key \
             -out /etc/pki/tls/certs/dummy.crt -days 109 \
             -subj "/C=xx/ST=xx/L=xx/O=xx/OU=xx/CN=xx"')
  end

  context 'with default parameters' do
    it 'should work without errors' do

      base_path = File.dirname(__FILE__)
      pp_path = File.join(base_path, 'fixtures', 'default.pp')
      pp = File.read(pp_path)

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe service('httpd') do
      it { is_expected.to be_running }
    end

    describe service('git-daemon') do
      it { is_expected.to be_running }
    end

    describe 'selinux' do
      it 'should have the httpd_enable_cgi boolean turned on' do
        shell("semanage boolean -l | grep '^httpd_enable_cgi'") do |r|
          expect(r.stdout).to match(/^httpd_enable_cgi.*\(on   ,   on\)/)
        end
      end

      it 'should allow port 80 and 443' do
        shell("semanage port -l | grep '^http_port_t'") do |r|
          expect(r.stdout).to match(/^http_port_t.*\b80,/)
          expect(r.stdout).to match(/^http_port_t.*\b443,/)
        end
      end

    end

  end

  context 'with behind_proxy => true' do
    it 'should work without errors' do

      base_path = File.dirname(__FILE__)
      pp_path = File.join(base_path, 'fixtures', 'behind_proxy.pp')
      pp = File.read(pp_path)

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe 'selinux' do
      it 'should allow port 8080 and 4443' do
        shell("semanage port -l | grep '^http_port_t'") do |r|
          expect(r.stdout).to match(/^http_port_t.*\b8080,/)
          expect(r.stdout).to match(/^http_port_t.*\b4443,/)
        end
      end
    end
  end
end

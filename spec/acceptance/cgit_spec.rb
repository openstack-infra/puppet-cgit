require 'spec_helper_acceptance'

describe 'cgit class' do

  context 'with default parameters' do
    it 'should work without errors' do

      # Generate unmanaged self-signed SSL certs for minimal deployment
      shell('openssl genrsa  -out /etc/pki/tls/private/dummy.key 2048')
      shell('openssl req -new -x509 -key /etc/pki/tls/private/dummy.key \
               -out /etc/pki/tls/certs/dummy.crt -days 109 \
               -subj "/C=xx/ST=xx/L=xx/O=xx/OU=xx/CN=xx"')

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

  end

end

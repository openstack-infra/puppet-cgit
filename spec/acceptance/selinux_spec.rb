require 'spec_helper_acceptance'

describe 'selinux', :if => ['fedora', 'redhat'].include?(os[:family]) do
  describe selinux do
    it { should be_permissive }
  end

  describe command('getsebool httpd_enable_cgi') do
    its(:stdout) { should match 'httpd_enable_cgi --> on' }
  end

  describe command('semanage port --list') do
    its(:stdout) { should match 'http_port_t' }
    its(:stdout) { should match 'git_port_t' }
  end
end

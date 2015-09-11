require 'spec_helper_acceptance'

describe 'required os packages', :if => ['fedora', 'redhat'].include?(os[:family]) do
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

describe 'required os packages', :if => ['debian', 'ubuntu'].include?(os[:family]) do
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

require 'spec_helper_acceptance'

describe 'required users and groups', :if => ['fedora', 'redhat'].include?(os[:family]) do
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

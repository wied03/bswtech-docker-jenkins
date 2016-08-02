require 'spec_helper'

describe 'Rockerfile' do
  describe file('/etc/redhat-release') do
    it { is_expected.to be_file }
    its(:content) { is_expected.to include 'Ubuntu' }
  end
end

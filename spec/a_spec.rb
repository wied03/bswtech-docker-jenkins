require 'spec_helper'

describe 'Rockerfile' do
  it "installs the right version of Ubuntu" do
    expect(os_version).to include("Ubuntu 14")
  end
end

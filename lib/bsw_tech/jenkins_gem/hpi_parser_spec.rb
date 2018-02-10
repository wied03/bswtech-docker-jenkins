require 'spec_helper'
require 'bsw_tech/jenkins_gem/hpi_parser'

describe BswTech::JenkinsGem::HpiParser do
  subject(:parser) {BswTech::JenkinsGem::HpiParser.new zip_stream}

  describe '#gem_spec' do
    subject { parser.gem_spec }

    let(:zip_stream) do
      # TODO: Fetch this dynamically if it does not exist
      File.open 'git.hpi', 'r'
    end

    its(:name) { is_expected.to eq 'jenkins-plugin-proxy-git' }
    its(:version) {is_expected.to eq Gem::Version.new('3.7.0')}
  end
end

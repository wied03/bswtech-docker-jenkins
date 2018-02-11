require 'spec_helper'
require 'bsw_tech/jenkins_gem/jenkins_list_fetcher'

describe BswTech::JenkinsGem::JenkinsListFetcher do
  describe '::get_available_versions' do
    subject {BswTech::JenkinsGem::JenkinsListFetcher.get_available_versions}

    it { is_expected.to include '2.89.3' }
    its(:length) { is_expected.to be > 3 }
  end
end


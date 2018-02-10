require 'spec_helper'
require 'bsw_tech/jenkins_gem/update_json_parser'

describe BswTech::JenkinsGem::UpdateJsonParser do
  subject(:parser) {BswTech::JenkinsGem::UpdateJsonParser.new(update_json_blob)}

  describe '#gem_listing' do
    subject(:gem_spec) {parser.gem_listing[0]}
    let(:update_json_blob) {
      <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
      CODE
    }

    describe 'basics' do
      its(:name) {is_expected.to eq 'jenkins-plugin-proxy-AnchorChain'}
      its(:description) {is_expected.to eq 'Adds links from a text file to sidebar on each build'}
      its(:version) {is_expected.to eq Gem::Version.new('1.0')}
      its(:homepage) {is_expected.to eq 'https://plugins.jenkins.io/AnchorChain'}
      its(:authors) do
        is_expected.to eq ['direvius@gmail.com']
      end
    end

    describe '#dependencies' do
      subject(:deps) {gem_spec.dependencies}

      context 'none' do
        its(:length) {is_expected.to eq 0}
      end

      context 'only required' do
        let(:update_json_blob) {
          <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[{"name":"maven-plugin","optional":false,"version":"2.9"}],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
          CODE
        }

        describe 'jenkins-plugin-proxy-maven-plugin' do
          subject(:dep) do
            expected_name = 'jenkins-plugin-proxy-maven-plugin'
            result = deps.find {|dependency| dependency.name == expected_name}
            fail "Unable to find dependency #{expected_name} in #{deps}" unless result
            result
          end

          describe '#requirement' do
            subject {dep.requirement.requirements}

            it {is_expected.to eq [['=', Gem::Version.new('2.9')]]}
          end
        end
      end

      context 'optional' do
        let(:update_json_blob) {
          <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[{"name":"maven-plugin","optional":true,"version":"2.9"}],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
          CODE
        }

        # Current Jenkins script ignores optional dependencies, so will we
        its(:length) {is_expected.to eq 0}
      end
    end

    context 'full file' do
      pending 'write this'
    end
  end
end

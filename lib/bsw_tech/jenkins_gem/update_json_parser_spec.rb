require 'spec_helper'
require 'bsw_tech/jenkins_gem/update_json_parser'

describe BswTech::JenkinsGem::UpdateJsonParser do
  let(:jenkins_versions) {['1.23']}

  subject(:parser) {BswTech::JenkinsGem::UpdateJsonParser.new(update_json_blob, jenkins_versions)}

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
      its(:summary) {is_expected.to eq 'Adds links from a text file to sidebar on each build'}
      its(:version) {is_expected.to eq Gem::Version.new('1.0')}
      its(:homepage) {is_expected.to eq 'https://plugins.jenkins.io/AnchorChain'}
      its(:authors) do
        is_expected.to eq ['direvius@gmail.com']
      end
      its(:metadata) {is_expected.to eq({
                                          'jenkins_version' => '1.0',
                                          'jenkins_name' => 'AnchorChain',
                                          'sha1' => 'rY1W96ad9TJI1F3phFG8X4LE26Q='
                                        })}
    end

    describe 'core Jenkins GEM' do
      subject(:gem_spec) do
        parser.gem_listing.find {|gem| gem.name.include? BswTech::JenkinsGem::UpdateJsonParser::JENKINS_CORE_PACKAGE}
      end

      its(:name) {is_expected.to eq 'jenkins-plugin-proxy-jenkins-core'}
      its(:summary) {is_expected.to eq 'Jenkins stub'}
      its(:version) {is_expected.to eq Gem::Version.new('1.23')}
      its(:homepage) {is_expected.to eq 'https://www.jenkins.io'}
      its(:authors) do
        is_expected.to eq ['alotofpeople']
      end
    end

    context '+ sign some plugins have' do
      let(:update_json_blob) {
        <<-CODE
  updateCenter.post(
  {"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0+123","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
        CODE
      }

      its(:version) {is_expected.to eq Gem::Version.new('1.0.123')}
      its(:metadata) {is_expected.to eq({
                                          'jenkins_version' => '1.0+123',
                                          'jenkins_name' => 'AnchorChain',
                                          'sha1' => 'rY1W96ad9TJI1F3phFG8X4LE26Q='
                                        })}
    end

    context 'dashes' do
      let(:update_json_blob) {
        <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0-123","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
        CODE
      }

      its(:version) {is_expected.to eq Gem::Version.new('1.0.123')}
      its(:metadata) {is_expected.to eq({
                                          'jenkins_version' => '1.0-123',
                                          'jenkins_name' => 'AnchorChain',
                                          'sha1' => 'rY1W96ad9TJI1F3phFG8X4LE26Q='
                                        })}
    end

    context 'no developer email address, which prevents GEM build' do
      let(:update_json_blob) {
        <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[],"developers":[{"developerId":"direvius"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0+123","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
        CODE
      }

      its(:authors) {is_expected.to eq ['direvius']}
    end

    context 'no developer at all, which prevents GEM build' do
      let(:update_json_blob) {
        <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[],"developers":[],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0+123","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
        CODE
      }

      its(:authors) {is_expected.to eq ['unknown']}
    end

    context 'description TODO' do
      let(:update_json_blob) {
        <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"TODO: Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
        CODE
      }

      its(:summary) {is_expected.to eq 'Adds links from a text file to sidebar on each build'}
    end

    describe '#dependencies' do
      subject(:deps) {gem_spec.dependencies}

      context 'none' do
        # Only Jenkins core
        its(:length) {is_expected.to eq 1}
      end

      context 'only required' do
        let(:update_json_blob) {
          <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[{"name":"maven-plugin","optional":false,"version":"2.9"}],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
          CODE
        }

        shared_examples :dependency do |name, version|
          expected_name = "jenkins-plugin-proxy-#{name}"
          describe expected_name do
            subject(:dep) do
              result = deps.find {|dependency| dependency.name == expected_name}
              fail "Unable to find dependency #{expected_name} in #{deps}" unless result
              result
            end

            describe '#requirement' do
              subject {dep.requirement.requirements}

              it {is_expected.to eq [['>=', Gem::Version.new(version)]]}
            end
          end
        end

        include_examples :dependency,
                         'maven-plugin',
                         '2.9'

        include_examples :dependency,
                         'jenkins-core',
                         '1.398'
      end

      context 'optional' do
        let(:update_json_blob) {
          <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[{"name":"maven-plugin","optional":true,"version":"2.9"}],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
          CODE
        }

        # Current Jenkins script ignores optional dependencies, so will we, only Jenkins
        its(:length) {is_expected.to eq 1}
      end

      context 'dash-version' do
        subject {deps[0].requirement.requirements[0]}

        let(:update_json_blob) {
          <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[{"name":"maven-plugin","optional":false,"version":"2.9-2"}],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
          CODE
        }

        it {is_expected.to eq ['>=', Gem::Version.new('2.9.2')]}
      end

      context 'dependency problems' do
        subject {deps[0].requirement.requirements[0]}

        BswTech::JenkinsGem::UpdateJsonParser::DEPENDENCY_REMAPS.each do |remap_plugin, versions|
          versions.each do |old_version, new_version|
            context "#{remap_plugin}" do
              let(:update_json_blob) {
                <<-CODE
updateCenter.post(
{"connectionCheckUrl":"http://www.google.com/","core":{"buildDate":"Feb 04, 2018","name":"core","sha1":"D8lrLmW+uYqWiSkGFhEXHhQ6I4w=","url":"http://updates.jenkins-ci.org/download/war/2.105/jenkins.war","version":"2.105"},"id":"default","plugins":{"AnchorChain":{"buildDate":"Mar 11, 2012","dependencies":[{"name": "#{remap_plugin}", "version": "#{old_version}"}],"developers":[{"developerId":"direvius","email":"direvius@gmail.com","name":"Alexey Lavrenuke"}],"excerpt":"Adds links from a text file to sidebar on each build","gav":"org.jenkins-ci.plugins:AnchorChain:1.0","labels":["report"],"name":"AnchorChain","releaseTimestamp":"2012-03-11T14:59:14.00Z","requiredCore":"1.398","scm":"https://github.com/jenkinsci/anchor-chain-plugin","sha1":"rY1W96ad9TJI1F3phFG8X4LE26Q=","title":"AnchorChain","url":"http://updates.jenkins-ci.org/download/plugins/AnchorChain/1.0/AnchorChain.hpi","version":"1.0","wiki":"https://plugins.jenkins.io/AnchorChain"}},"signature":{}, "updateCenterVersion": "1", "warnings": []});
                CODE
              }

              it {is_expected.to eq ['>=', Gem::Version.new(new_version)]}
            end
          end
        end
      end
    end

    context 'full file' do
      let(:update_json_blob) {File.read 'spec/ruby_code/update_full.json'}

      subject {parser.gem_listing}

      its(:length) {is_expected.to eq 1452}
    end
  end
end

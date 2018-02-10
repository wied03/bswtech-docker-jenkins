require 'spec_helper'
require 'bsw_tech/jenkins_gem/manifest_parser'

describe BswTech::JenkinsGem::ManifestParser do
  subject(:parser) {BswTech::JenkinsGem::ManifestParser.new(manifest_contents)}

  describe '#gem_spec' do
    context 'required dependencies' do
      subject(:gem_spec) {parser.gem_spec}

      let(:manifest_contents) {
        <<-CODE
Manifest-Version: 1.0
Archiver-Version: Plexus Archiver
Created-By: Apache Maven
Built-By: mwaite
Build-Jdk: 1.8.0_151
Extension-Name: git
Specification-Title: Integrates Jenkins with GIT SCM
Implementation-Title: git
Implementation-Version: 3.7.0
Group-Id: org.jenkins-ci.plugins
Short-Name: git
Long-Name: Jenkins Git plugin
Url: http://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin
Plugin-Version: 3.7.0
Hudson-Version: 1.625.3
Jenkins-Version: 1.625.3
Plugin-Dependencies: workflow-scm-step:1.14.2,credentials:2.1.14,git-c
 lient:2.7.0
Plugin-Developers: Kohsuke Kawaguchi:kohsuke:,Mark Waite:MarkEWaite:ma
 rk.earl.waite@gmail.com


        CODE
      }

      its(:name) {is_expected.to eq 'jenkins-plugin-proxy-git'}
      its(:description) {is_expected.to eq 'Integrates Jenkins with GIT SCM'}
      its(:summary) {is_expected.to eq 'Jenkins Git plugin'}
      its(:version) {is_expected.to eq Gem::Version.new('3.7.0')}
      its(:homepage) {is_expected.to eq 'http://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin'}
      its(:authors) do
        is_expected.to eq ['Kohsuke Kawaguchi:kohsuke:',
                           'Mark Waite:MarkEWaite:mark.earl.waite@gmail.com']
      end

      describe '#dependencies' do
        subject(:deps) {gem_spec.dependencies}

        its(:length) {is_expected.to eq 3}

        shared_examples :dependencies do |name, version|
          describe name do
            expected_name = "jenkins-plugin-proxy-#{name}"

            subject(:dep) do
              result = deps.find {|dependency| dependency.name == expected_name}
              fail "Unable to find dependency #{expected_name} in #{deps}" unless result
              result
            end

            its(:name) {is_expected.to eq expected_name}

            describe '#requirement' do
              subject {dep.requirement.requirements}

              it {is_expected.to eq [['=', Gem::Version.new(version)]]}
            end
          end

        end

        include_examples :dependencies,
                         'workflow-scm-step', '1.14.2'
        include_examples :dependencies,
                         'credentials', '2.1.14'
        include_examples :dependencies,
                         'git-client', '2.7.0'
      end
    end
  end
end

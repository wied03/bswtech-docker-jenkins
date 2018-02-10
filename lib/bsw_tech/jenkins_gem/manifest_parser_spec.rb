require 'spec_helper'
require 'bsw_tech/jenkins_gem/manifest_parser'

describe BswTech::JenkinsGem::ManifestParser do
  subject(:parser) {BswTech::JenkinsGem::ManifestParser.new(manifest_contents)}

  describe '#gem_spec' do
    context 'has dependencies' do
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
 lient:2.7.0,mailer:1.18,matrix-project:1.7.1,parameterized-trigger:2.
 33;resolution:=optional,promoted-builds:2.27;resolution:=optional,scm
 -api:2.2.0,ssh-credentials:1.13,structs:1.10,token-macro:1.12.1;resol
 ution:=optional
Plugin-Developers: Kohsuke Kawaguchi:kohsuke:,Mark Waite:MarkEWaite:ma
 rk.earl.waite@gmail.com


        CODE
      }

      describe '#description' do
        subject {gem_spec.description}

        it {is_expected.to eq 'Integrates Jenkins with GIT SCM'}
      end

      pending 'write this'
    end
  end
end

require 'spec_helper'
require 'retryable'

describe 'Jenkins container' do
  JENKINS_HOME_IMAGE = '/var/jenkins_home'

  def with_retry
    Retryable.retryable(tries: 15,
                        on: RSpec::Expectations::ExpectationNotMetError,
                        sleep: 5) do
      yield
    end
  end

  describe package('jenkins') do
    it { is_expected.to be_installed }
  end

  describe package('git') do
    it { is_expected.to be_installed }
  end

  it 'listens on port 8080' do
    with_retry do
      cmd = command('curl http://localhost:8080')
      expect(cmd.exit_status).to eq 0
      expect(cmd.stdout).to include '<html>'
    end
  end

  def wait_for_jenkins
    with_retry do
      output = `docker logs #{current_container_id} 2>&1`
      expect(output).to include 'Jenkins initial setup is required'
      expect(output).to include 'INFO: Jenkins is fully up and running'
      output
    end
  end

  it 'fully starts up' do
    wait_for_jenkins
  end

  it 'shows no ERRORs in logs' do
    output = wait_for_jenkins
    # asserting these after up and running should catch stuff
    expect(output).to_not include 'ERROR'
    expect(output).to_not include 'Exception'
    expect(output).to_not include 'SEVERE'
  end

  it 'shows no warnings in logs' do
    output = wait_for_jenkins
    # This should not be a big deal, its plugins that we do not control
    expected_unpackaged_classes_plugin_messages = [
        'jira',
        'jsch'
    ].select do |plugin|
      "Deprecated unpacked classes directory found in /usr/lib/jenkins/plugins/../plugins/#{plugin}/WEB-INF/classes"
    end
    exclusions = [
      'Unknown version string [3.1]',
      'Empty contextPath',
      'Security role name ** used in an <auth-constraint> without being defined in a <security-role>',
      # https://issues.jenkins-ci.org/browse/JENKINS-48480 - Not a real warning
      'This Jenkins instance uses deprecated Remoting protocols'
    ] + expected_unpackaged_classes_plugin_messages
    warning_lines = output.lines.select do |line|
      # empty contextPath is an expected error
      line.include?('WARN') && !exclusions.any? { |e| line.include?(e)}
    end
    expect(warning_lines).to be_empty
  end

  describe docker_container do
    it { is_expected.to exist }
    it { is_expected.to be_running }
  end

  JENKINS_UID = ENV['JENKINS_UID']

  describe command('id') do
    its(:stdout) { is_expected.to include "uid=#{JENKINS_UID}" }
  end

  describe file(JENKINS_HOME_IMAGE) do
    it { is_expected.to exist }
    it { is_expected.to be_directory }
    it { is_expected.to be_owned_by JENKINS_UID }
  end

  ['/var/cache/tomcat/work',
   '/var/cache/tomcat/temp',
   '/usr/share/tomcat/work'].each do |dir|
    describe file(dir) do
      it { is_expected.to exist }
      it { is_expected.to be_directory }
      it { is_expected.to be_owned_by JENKINS_UID}
    end
  end

  describe group('jenkins') do
    it { is_expected.to exist }
  end

  describe command('grep Cap /proc/self/status') do
    its(:stdout) { is_expected.to_not match /Cap\S+:\s+0+[a-z]+/m }
  end

  describe command('touch /howdy') do
    its(:exit_status) { is_expected.to eq 1 }
    its(:stderr) { is_expected.to match /touch: cannot touch '\/howdy'.*/ }
  end
end

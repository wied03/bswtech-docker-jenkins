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
    it {is_expected.to be_installed}
  end

  describe package('git') do
    it {is_expected.to be_installed}
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
      expect(output).to match /INFO.*Jenkins is fully up and running/
      output
    end
  end

  it 'fully starts up' do
    output = wait_for_jenkins
    puts "Jenkins log: #{output}"
  end

  it 'shows no ERRORs in logs' do
    output = wait_for_jenkins
    triggers = [
      'error',
      'failed',
      'exception',
      'severe'
    ]
    error_lines = output.lines.select do |line|
      triggers.any? {|trigger| line.upcase.include?(trigger.upcase)}
    end
    filtered_errors = []
    found = false
    error_lines.each do |line|
      # https://github.com/jenkinsci/build-timeout-plugin/issues/67
      if line.include? 'h.ExtensionFinder$GuiceFinder$FaultTolerantScope$1#error: Failed to instantiate optional component hudson.plugins.build_timeout.operations.AbortAndRestartOperation$DescriptorImpl; skipping'
        found = true
        puts "Ignoring #{line}"
      else
        filtered_errors << line
      end
    end
    expect(found).to eq(true),
                     'Expected our error in here'
    expect(filtered_errors).to be_empty
  end

  it 'shows no warnings in logs' do
    output = wait_for_jenkins
    # This should not be a big deal, its plugins that we do not control
    expected_unpackaged_classes_plugin_messages = [
      'jquery-ui',
    ].map do |plugin|
      "Deprecated unpacked classes directory found in /usr/lib/jenkins/plugins/../plugins/#{plugin}.hpi/WEB-INF/classes"
    end
    exclusions = [
      'Unknown version string [3.1]',
      'Empty contextPath',
      'Security role name ** used in an <auth-constraint> without being defined in a <security-role>',
      "i.j.p.casc.BaseConfigurator#createAttribute: Can't handle class com.google.jenkins.plugins.credentials.oauth.JsonServiceAccountConfig#jsonKeyFileUpload: type is abstract but not Describable"
    ] + expected_unpackaged_classes_plugin_messages
    warning_lines = output.lines.select do |line|
      if line.upcase.include?('WARN')
        excluded = exclusions.any? do |e|
          match = line.include?(e)
          puts "Excluding warning '#{line}' due to exclusion '#{e}'" if match
          match
        end
        !excluded
      end
    end
    expect(warning_lines).to be_empty
  end

  describe docker_container do
    it {is_expected.to exist}
    it {is_expected.to be_running}
  end

  # Need the NSS Wrapper to get these
  NSS_WRAPPED = '/usr/local/bin/jenkins.sh'

  describe command("#{NSS_WRAPPED} getent passwd jenkins") do
    its(:stdout) {is_expected.to include 'jenkins:x:1002:1002:Jenkins user:/var/jenkins_home:/bin/bash'}
  end

  describe command("#{NSS_WRAPPED} id") do
    its(:stdout) {is_expected.to include 'uid=1002(jenkins)'}
  end

  describe file(JENKINS_HOME_IMAGE) do
    it {is_expected.to exist}
    it {is_expected.to be_directory}
    it {is_expected.to be_owned_by JENKINS_UID}
  end

  describe command('grep Cap /proc/self/status') do
    its(:stdout) {is_expected.to_not match /Cap\S+:\s+0+[a-z]+/m}
  end

  describe command('touch /howdy') do
    its(:exit_status) {is_expected.to eq 1}
    its(:stderr) {is_expected.to match /touch: cannot touch '\/howdy'.*/}
  end
end

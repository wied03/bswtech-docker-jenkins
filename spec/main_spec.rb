require 'spec_helper'
require 'retryable'

describe 'Jenkins container' do
  JENKINS_HOME_IMAGE = '/var/jenkins_home'

  def with_retry
    Retryable.retryable(tries: 10,
                        on: RSpec::Expectations::ExpectationNotMetError,
                        sleep: 5) do
      yield
    end
  end

  it 'listens on port 8080' do
    with_retry do
      cmd = command('curl http://localhost:8080')
      expect(cmd.exit_status).to eq 0
      expect(cmd.stdout).to include '<html>'
    end
  end

  it 'shows no errors in logs' do
    with_retry do
      output = `docker logs #{current_container_id} 2>&1`
      expect(output).to include 'Running from: /usr/lib/jenkins/jenkins.war'
      expect(output).to include 'Jenkins initial setup is required'
      expect(output).to include 'INFO: Jenkins is fully up and running'
      expect(output).to_not include 'ERROR'
      # empty contextPath is an expected error
      expect(output).to_not match /WARN(?!ING: Empty contextPath)/m
    end
  end

  describe docker_container do
    it { is_expected.to exist }
    it { is_expected.to be_running }
    it { is_expected.to have_volume JENKINS_HOME_IMAGE, JENKINS_VOLUME }
  end

  describe user('jenkins') do
    it { is_expected.to exist }
    it { is_expected.to have_uid 991 }
    it { is_expected.to have_home_directory JENKINS_HOME_IMAGE }
    it { is_expected.to have_login_shell '/bin/false' }
    it { is_expected.to belong_to_primary_group 'jenkins' }
  end

  describe command('whoami') do
    its(:stdout) { is_expected.to include 'jenkins' }
  end

  describe file(JENKINS_HOME_IMAGE) do
    it { is_expected.to exist }
    it { is_expected.to be_directory }
    it { is_expected.to be_owned_by 'jenkins' }
  end

  describe group('jenkins') do
    it { is_expected.to exist }
    it { is_expected.to have_gid 991 }
  end

  describe command('grep Cap /proc/self/status') do
    its(:stdout) { is_expected.to_not match /Cap\S+:\s+0+[a-z]+/m }
  end

  describe command('touch /howdy') do
    its(:exit_status) { is_expected.to eq 1 }
    its(:stderr) { is_expected.to match /touch: cannot touch '\/howdy': Read-only file system/ }
  end unless ENV['NO_TMPFS_OPTIONS'] # jenkins needs a tmpfs option mac doesn't support
end

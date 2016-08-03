require 'spec_helper'
require 'retryable'

describe 'Jenkins container' do
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
    it { is_expected.to have_volume '/var/jenkins_home', JENKINS_VOLUME }
  end

  pending 'JIRA'
end

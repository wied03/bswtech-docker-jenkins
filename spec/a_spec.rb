require 'spec_helper'
require 'retryable'

describe 'Jenkins container' do
  xit 'listens on port 8080' do
    Retryable.retryable(tries: 10,
                        on: RSpec::Expectations::ExpectationNotMetError,
                        sleep: 5) do
      cmd = command('curl http://localhost:8080')
      expect(cmd.exit_status).to eq 0
      expect(cmd.stdout).to include '<html>'
    end
  end

  describe 'docker logs' do
    pending
  end

  it 'shows logs without errors' do
    pending "#{current_container_id}"
  end

  describe docker_container do
    it { is_expected.to exist }
    it { is_expected.to be_running }
    it { is_expected.to have_volume '/var/jenkins_home', JENKINS_VOLUME }
  end

  pending 'JIRA'
end

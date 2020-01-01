require 'serverspec'
require 'serverspec_patch'
require 'docker'

set :backend, :docker
set :docker_image, ENV['IMAGE_TAG']
# testing this can take a while
Docker.options[:read_timeout] = 120
JENKINS_UID = ENV['JENKINS_UID']
JENKINS_GID = ENV['JENKINS_GID']
TMPFS_FLAGS = "uid=#{JENKINS_UID},gid=#{JENKINS_GID}"

docker_options = {
  'User' => "#{JENKINS_UID}:#{JENKINS_GID}",
  'Volumes' => {
    '/var/jenkins_home' => {}
  },
  'Env' => [
    "JENKINS_URL=http://foo"
  ],
  'HostConfig' => {
    'Binds' => [
      "#{ENV['TEST_VOL_DIR']}:/var/jenkins_home:Z"
    ],
    'CapDrop' => ['all'],
    'ReadonlyRootfs' => true,
    'Tmpfs' => {
      '/run' => '',
      '/tmp' => 'exec', # needed for a jenkins startup command
    }
  }
}

set :docker_container_create_options, docker_options

RSpec.configure do |config|
  config.include DockerSpecHelper

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
  config.fail_if_no_examples = true
end

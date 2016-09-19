require 'serverspec'
require 'serverspec_patch'
require 'docker'

set :backend, :docker
set :docker_image, ENV['IMAGE_TAG']
# testing this can take a while
Docker.options[:read_timeout] = 120
JENKINS_VOLUME = ENV['TEST_VOLUME']

docker_options = {
  'Volumes' => {
    '/var/jenkins_home' => {}
  },
  'HostConfig' => {
    'Binds' => ["#{JENKINS_VOLUME}:/var/jenkins_home:Z"],
    'CapDrop' => ['all']
  }
}

unless ENV['NO_TMPFS_OPTIONS']
  host = docker_options['HostConfig']
  host.merge!({
    'ReadonlyRootfs' => true,
      'Tmpfs' => {
        '/run' => '',
        '/etc/docker' => '',
        '/tmp' => 'exec' # needed for a jenkins startup command
      }
    })
end

set :docker_container_create_options, docker_options

RSpec.configure do |config|
  config.include DockerSpecHelper

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
end

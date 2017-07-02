require 'serverspec'
require 'serverspec_patch'
require 'docker'

set :backend, :docker
set :docker_image, ENV['IMAGE_TAG']
# testing this can take a while
Docker.options[:read_timeout] = 120
JENKINS_VOLUME = ENV['TEST_VOLUME']

TMPFS_FLAGS = "uid=#{ENV['JENKINS_UID']},gid=#{ENV['JENKINS_GID']}"
docker_options = {
  'Volumes' => {
    '/var/jenkins_home' => {}
  },
  'HostConfig' => {
    'Binds' => ["#{JENKINS_VOLUME}:/var/jenkins_home:Z"],
    'CapDrop' => ['all'],
    'ReadonlyRootfs' => true,
    'Tmpfs' => {
      '/run' => '',
      '/tmp' => 'exec', # needed for a jenkins startup command
      '/usr/share/tomcat/work' => '',
      '/var/cache/tomcat/temp' => "#{TMPFS_FLAGS},exec",
      '/var/cache/tomcat/work' => TMPFS_FLAGS
    }
  }
}

set :docker_container_create_options, docker_options

RSpec.configure do |config|
  config.include DockerSpecHelper

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
end

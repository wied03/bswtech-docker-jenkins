require 'serverspec'
require 'serverspec_patch'
require 'docker'

set :backend, :docker
set :docker_image, ENV['IMAGE_TAG']
# testing this can take a while
Docker.options[:read_timeout] = 120
JENKINS_UID = ENV['JENKINS_UID']

TMPFS_FLAGS = "uid=#{JENKINS_UID},gid=#{ENV['JENKINS_GID']}"
docker_options = {
  'User' => JENKINS_UID,
  'HostConfig' => {
    'CapDrop' => ['all'],
    'ReadonlyRootfs' => true,
    'Tmpfs' => {
      '/run' => '',
      '/tmp' => 'exec', # needed for a jenkins startup command
      '/usr/share/tomcat/work' => TMPFS_FLAGS,
      '/var/cache/tomcat/temp' => "#{TMPFS_FLAGS},exec",
      '/var/cache/tomcat/work' => TMPFS_FLAGS
    }
  }
}

set :docker_container_create_options, docker_options

# TODO: Move this to a shared GEM
def set_volumes(volumes)
  opts = Specinfra.configuration.docker_container_create_options
  host_config = opts['HostConfig'] ||= {}
  host_config['Binds'] = volumes.map { |name, image_path| "#{name}:#{image_path}" }
  Specinfra.backend.cleanup_volumes = volumes
end

volumes = {
  'jenkins_test_home' => '/var/jenkins_home:Z'
}

set_volumes volumes

RSpec.configure do |config|
  config.include DockerSpecHelper

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
  config.fail_if_no_examples = true
end

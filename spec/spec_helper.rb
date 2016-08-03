require 'serverspec'
require 'serverspec_patch'

set :backend, :docker
set :docker_image, ENV['IMAGE_TAG']
JENKINS_VOLUME = File.join Dir.pwd, 'jenkins_test_home'

# Clean cannot go in RSpec hooks because serverspec connects ahead of time
FileUtils.rm_rf JENKINS_VOLUME unless ENV['NO_CLEANUP']

set :docker_container_create_options, {
  #'User' => 'nonrootuser',
  'Volumes' => {
    '/var/jenkins_home' => {}
  },
  'HostConfig' => {
    'Binds' => ["#{JENKINS_VOLUME}:/var/jenkins_home"]
  }
}

RSpec.configure do |config|
  config.include DockerSpecHelper

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
end

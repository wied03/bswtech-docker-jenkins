require 'serverspec'
require 'serverspec_patch'

set :backend, :docker
set :docker_image, ENV['IMAGE_TAG']
JENKINS_VOLUME = File.join Dir.pwd, 'jenkins_test_home'
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
  config.before(:suite) do
    FileUtils.rm_rf JENKINS_VOLUME unless ENV['NO_CLEANUP']
  end

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
end

require 'serverspec'

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
  config.before(:suite) do
    FileUtils.rm_rf JENKINS_VOLUME
  end
end

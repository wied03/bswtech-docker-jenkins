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

module DockerSpecHelper
  def current_container_id
    Specinfra.backend.instance_variable_get(:@container).id
  end
end

RSpec.configure do |config|
  config.include DockerSpecHelper
  config.before(:suite) do
    #FileUtils.rm_rf JENKINS_VOLUME
  end
end

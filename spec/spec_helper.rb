require 'serverspec'

set :backend, :docker
set :docker_image, ENV['IMAGE_TAG']

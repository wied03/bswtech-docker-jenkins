require 'serverspec'
require 'docker'

image_id = `docker images -q bswtech/rocker_first:1`.strip
set :backend, :docker
set :docker_image, image_id

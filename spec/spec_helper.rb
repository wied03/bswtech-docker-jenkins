require 'serverspec'

image_tag = ENV['IMAGE_TAG'] || 'bswtech/rocker_first:1.0'
image_id = `docker images -q #{image_tag}`.strip
set :backend, :docker
set :docker_image, image_id

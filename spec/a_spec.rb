require 'spec_helper'

describe docker_image('bswtech/rocker_first:1') do
  it { should exist }
end

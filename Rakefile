require 'rake'
require 'rspec/core/rake_task'

task :default => [:build, :spec]

if ENV['GENERATE_REPORTS'] == 'true'
  require 'ci/reporter/rake/rspec'
  task :spec => 'ci:setup:rspec'
end

desc "Run serverspec tests"
RSpec::Core::RakeTask.new(:spec)

desc 'Builds Docker image'
task :build do
  imageTag = ENV['IMAGE_TAG'] || 'bswtech/rocker_first:1.0'
  sh "rocker build -var ImageTag=#{imageTag}"
end

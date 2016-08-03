require 'rake'
require 'rspec/core/rake_task'

task :default => [:build, :spec]

if ENV['GENERATE_REPORTS'] == 'true'
  require 'ci/reporter/rake/rspec'
  task :spec => 'ci:setup:rspec'
end

desc "Run serverspec tests"
RSpec::Core::RakeTask.new(:spec => :build)

image_version = ENV['IMAGE_VERSION'] || '0.1.1'
ENV['IMAGE_TAG'] = image_tag = "bswtech/bswtech-docker-jenkins:#{image_version}"

desc "Builds Docker image #{image_tag}"
task :build do
  args = {
    'JenkinsHome' => '/var/jenkins_home',
    'ImageTag' => image_tag
  }
  flat_args = args.map {|key,val| "-var #{key}=#{val}"}.join ' '
  sh "rocker build #{flat_args}"
end

desc "Pushes out docker image #{image_tag} to the registry"
task :push => :build do
  quay_repo_tag = "quay.io/brady/bswtech-docker-jenkins:#{image_version}"
  sh "docker tag #{image_tag} #{quay_repo_tag}"
  sh "docker push #{quay_repo_tag}"
end

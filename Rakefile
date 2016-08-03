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
    'TiniVersion' => '0.9.0',
    'TiniSha' => 'fa23d1e20732501c3bb8eeeca423c89ac80ed452',
    'JenkinsHome' => '/var/jenkins_home',
    'ImageTag' => image_tag,
    'JenkinsVersion' => '2.7.1-1.1',
    'JdkVersion' => '1.8.0.101-3.b13.el7_2',
    'JenkinsWarDir' => '/usr/lib/jenkins' # from RPM
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

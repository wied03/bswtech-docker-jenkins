require 'rake'
require 'rspec/core/rake_task'

task :default => [:build, :spec]

if ENV['GENERATE_REPORTS'] == 'true'
  require 'ci/reporter/rake/rspec'
  task :spec => 'ci:setup:rspec'
end

ENV['TEST_VOLUME'] = TEST_VOLUME = File.join Dir.pwd, 'jenkins_test_home'
# https://github.com/docker/docker/issues/20740 - mac doesn't work with this
ENV['NO_TMPFS_OPTIONS'] = '1' unless ENV['JENKINS_URL']
JENKINS_USER = 'jenkins'
JENKINS_GROUP = 'jenkins'
JENKINS_GID = 991
JENKINS_UID = 991

task :clean_test_volume do
  # Clean cannot go in RSpec hooks because serverspec connects ahead of time
  # Can't go in spec helper because we create the test user first and don't want the directory
  # to be overwritten
  rm_rf TEST_VOLUME unless ENV['NO_CLEANUP']
end

# Docker mac does not replicate problem like CI does
desc 'Creates test user on Jenkins slave'
task :test_user => :clean_test_volume do
  next unless ENV['JENKINS_URL']
  # jenkins slave will have root access
  sh "groupadd -g #{JENKINS_GID} #{JENKINS_GROUP}"
  sh "useradd -r -u #{JENKINS_UID} -g #{JENKINS_GID} -m -d #{TEST_VOLUME} -s /bin/false #{JENKINS_USER}"
  at_exit {
    sh "userdel -r #{JENKINS_USER}"
  }
end

desc "Run serverspec tests"
RSpec::Core::RakeTask.new(:spec => [:build, :clean_test_volume, :test_user])

image_version = ENV['IMAGE_VERSION'] || '0.1.1'
ENV['IMAGE_TAG'] = image_tag = "bswtech/bswtech-docker-jenkins:#{image_version}"

desc "Builds Docker image #{image_tag}"
task :build do
  args = {
    'JenkinsGid' => JENKINS_GID,
    'JenkinsGroup' => JENKINS_GROUP,
    'JenkinsUid' => JENKINS_UID,
    'JenkinsUser' => JENKINS_USER,
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

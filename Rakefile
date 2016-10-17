require 'rake'
require 'rspec/core/rake_task'
require 'digest'

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
JENKINS_GID = 1002
JENKINS_UID = 1002

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

JENKINS_VERSION = '2.7.2-1.1'
JAVA_VERSION = '1.8.0.102-1.b14.el7_2'
GIT_VERSION = '1.8.3.1-6.el7_2.1'
MINOR_VERSION = ENV['MINOR_VERSION'] || '1'
# Drop the RPM subrelease
image_version = "#{Gem::Version.new(JENKINS_VERSION).release}.#{MINOR_VERSION}"
ENV['IMAGE_TAG'] = image_tag = "bswtech/bswtech-docker-jenkins:#{image_version}"

task :plugin_manager_override do
  sh './gradlew build'
end

JENKINS_BIN_DIR='/usr/lib/jenkins'
desc "Builds Docker image #{image_tag}"
task :build => :plugin_manager_override do
  args = {
    'JenkinsGid' => JENKINS_GID,
    'JenkinsGroup' => JENKINS_GROUP,
    'JenkinsUid' => JENKINS_UID,
    'JenkinsUser' => JENKINS_USER,
    'ImageTag' => image_tag,
    'ImageVersion' => image_version,
    'JenkinsVersion' => JENKINS_VERSION,
    'JavaPackage' => "java-1.8.0-openjdk-#{JAVA_VERSION}", # can't use java headless because hudson.util.ChartUtil needs some X11 stuff
    'JavaDevPackage' => "java-1.8.0-openjdk-devel-#{JAVA_VERSION}",
    'GitPackage' => "git-#{GIT_VERSION}",
    'JenkinsBinDir' => JENKINS_BIN_DIR,
    'JenkinsWarFile' => File.join(JENKINS_BIN_DIR, 'jenkins.war'),
    'PluginHash' => Digest::SHA256.hexdigest(File.read('plugins/install_plugins.txt'))
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

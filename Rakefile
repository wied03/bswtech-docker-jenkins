require 'rake'
require 'rspec/core/rake_task'
require 'digest'

task :default => [:build, :spec]

if ENV['GENERATE_REPORTS'] == 'true'
  require 'ci/reporter/rake/rspec'
  task :spec => 'ci:setup:rspec'
end

JENKINS_USER = 'jenkins'
JENKINS_GROUP = 'jenkins'
JENKINS_GID = ENV['JENKINS_GID'] = '1002'
JENKINS_UID = ENV['JENKINS_UID'] = '1002'

ON_MAC = RUBY_PLATFORM.include?('darwin')

# Docker mac does not replicate problem like CI does
desc 'Creates test user on Jenkins slave'
task :test_user do
  next unless ENV['JENKINS_URL']
  # jenkins slave will have root access
  sh "groupadd -g #{JENKINS_GID} #{JENKINS_GROUP}"
  sh "useradd -r -u #{JENKINS_UID} -g #{JENKINS_GID} -m -s /bin/false #{JENKINS_USER}"
  at_exit {
    sh "userdel -r #{JENKINS_USER}"
  }
end

desc 'Run serverspec tests with actual container'
RSpec::Core::RakeTask.new(:spec => [:build, :test_user])

JENKINS_VERSION = '2.89.3-1.1'
JAVA_VERSION = '1.8.0.161-0.b14.el7_4'
GIT_VERSION = '1.8.3.1-12.el7_4'
MINOR_VERSION = ENV['MINOR_VERSION'] || '1'
# Drop the RPM subrelease when we build our image
VERSION_NO_SUBRELEASE = Gem::Version.new(JENKINS_VERSION).release
IMAGE_VERSION = "#{VERSION_NO_SUBRELEASE}.#{MINOR_VERSION}"
ENV['IMAGE_TAG'] = image_tag = "bswtech/bswtech-docker-jenkins:#{IMAGE_VERSION}"

TMPFS_FLAGS = "uid=#{JENKINS_UID},gid=#{JENKINS_GID}"
desc 'Run the actual container for manual testing'
task :test_run => :build do
  at_exit {
    sh 'docker rm -f jenkins'
    sh 'docker volume rm jenkins_test_volume'
  }

  sh "docker run -v jenkins_test_volume:/var/jenkins_home:Z --cap-drop=all --read-only --tmpfs=/usr/share/tomcat/work --tmpfs=/var/cache/tomcat/temp:#{TMPFS_FLAGS},exec --tmpfs=/var/cache/tomcat/work:#{TMPFS_FLAGS} --tmpfs=/run --tmpfs=/tmp:exec -P --name jenkins #{image_tag}"
end

task :update_gradle_jenkins_dep do
  # mac sed
  sed_replace = RUBY_PLATFORM.include?('darwin') ? '-i .bak' : '-i'
  # Want the version we build the plugin manager against to be consistent
  sh "sed #{sed_replace} \"s/org.jenkins-ci.main:jenkins-core:.*/org.jenkins-ci.main:jenkins-core:#{VERSION_NO_SUBRELEASE}'/\" ./build.gradle"
  sh 'rm -f *.bak'
end

task :plugin_manager_override => :update_gradle_jenkins_dep do
  sh './gradlew build'
end

GEN_PLUGIN_FILENAME = 'plugins/Gemfile.lock'
task :fetch_plugins do
  Dir.chdir('plugins') do
    Bundler.with_clean_env do
      sh "JENKINS_VERSION=#{VERSION_NO_SUBRELEASE} ./jenkins_bundle_install.sh"
    end
  end
end

desc 'Display plugin dependency graph'
task :display_plugins do
  Dir.chdir('plugins') do
    Bundler.with_clean_env do
      sh "JENKINS_VERSION=#{VERSION_NO_SUBRELEASE} bundle list"
    end
  end
end

JENKINS_BIN_DIR = '/usr/lib/jenkins'
desc "Builds Docker image #{image_tag}"
task :build => [:plugin_manager_override, :fetch_plugins] do
  # not using docker COPY, so need to force changes
  resources_hash = FileList['resources/**'].inject do |exist, file|
    Digest::SHA256.hexdigest(Digest::SHA256.hexdigest(exist) + File.read(file))
  end
  base_version = ENV['DOCKER_BASE_VERSION'] || '1.0.44'
  args = {
    'JenkinsGid' => JENKINS_GID,
    'JenkinsGroup' => JENKINS_GROUP,
    'JenkinsUid' => JENKINS_UID,
    'JenkinsUser' => JENKINS_USER,
    'ImageTag' => image_tag,
    'ImageVersion' => IMAGE_VERSION,
    'JenkinsVersion' => JENKINS_VERSION,
    'JavaPackage' => "java-1.8.0-openjdk-#{JAVA_VERSION}", # can't use java headless because hudson.util.ChartUtil needs some X11 stuff
    'GitPackage' => "git-#{GIT_VERSION}",
    'JenkinsBinDir' => JENKINS_BIN_DIR,
    'PluginHash' => Digest::SHA256.hexdigest(File.read(GEN_PLUGIN_FILENAME)),
    'ResourcesHash' => resources_hash,
    'BaseVersion' => base_version
  }
  flat_args = args.map {|key, val| "-var #{key}=#{val}"}.join ' '
  begin
    # SELinux causes problems when trying to use the Rocker MOUNT directive
    sh 'setenforce 0' unless ON_MAC
    sh "rocker build #{flat_args}"
  ensure
    sh 'setenforce 1' unless ON_MAC
  end
end

desc "Pushes out docker image #{image_tag} to the registry"
task :push => :build do
  quay_repo_tag = "quay.io/brady/bswtech-docker-jenkins:#{IMAGE_VERSION}"
  sh "docker tag #{image_tag} #{quay_repo_tag}"
  sh "docker push #{quay_repo_tag}"
end

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

JENKINS_VERSION = '2.19.2-1.1'
JAVA_VERSION = '1.8.0.111-1.b15.el7_2'
GIT_VERSION = '1.8.3.1-6.el7_2.1'
MINOR_VERSION = ENV['MINOR_VERSION'] || '1'
# Drop the RPM subrelease when we build our image
VERSION_NO_SUBRELEASE = Gem::Version.new(JENKINS_VERSION).release
IMAGE_VERSION = "#{VERSION_NO_SUBRELEASE}.#{MINOR_VERSION}"
ENV['IMAGE_TAG'] = image_tag = "bswtech/bswtech-docker-jenkins:#{IMAGE_VERSION}"

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

task :digital_ocean_plugin do
  sh 'git clone https://github.com/jenkinsci/digitalocean-plugin.git' unless Dir.exist?('digitalocean-plugin')
  Dir.chdir 'digitalocean-plugin' do
    sh 'git checkout 56ef608886a41dad5ba4778191b393a0f9e3aac9'
    sh 'mvn -DskipTests package'
  end
end

# Read by Jenkins repo's script that downloads plugins+deps
GEN_PLUGIN_FILENAME = 'plugins/install_plugins.txt'

task :generate_plugin_list do
  plugins = [
    'build-timeout:1.17.1', # Standard Jenkins
    'docker-workflow:1.9', # CloudBees Docker Pipeline
    'credentials:2.1.8', # Core credentials plugin
    'credentials-binding:1.9', # Allow use of creds in environment variables/pipeline steps
    'email-ext:2.52', # better email extensions
    'git:3.0.0',
    'workflow-aggregator:2.4', # the actual core pipeline plugin
    'pipeline-graph-analysis:1.2',
    'ssh-agent:1.13', # We use this for core-ansible for SSH credentials
    'timestamper:1.8.7', # Base jenkins package, adds them to console output
    'ws-cleanup:0.32', # Workspace cleanup
    'antisamy-markup-formatter:1.5', # OWASP HTML sanitizer for text fields, standard Jenkins
    'ldap:1.13', # Samba authentication needs this
    'matrix-auth:1.4' # Not using it yet but the option to do matrix based authorization is good to have and standard
  ]
  # Will be read by shell script (plugins/install-plugins/sh)
  File.write(GEN_PLUGIN_FILENAME, plugins.join("\n"))
end

JENKINS_BIN_DIR='/usr/lib/jenkins'
INSTALLED_PLUGINS_FILE=File.join(JENKINS_BIN_DIR, 'installed_plugins.txt')
desc "Builds Docker image #{image_tag}"
task :build => [:plugin_manager_override, :digital_ocean_plugin, :generate_plugin_list] do
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
    'InstalledPluginsFile' => INSTALLED_PLUGINS_FILE,
    'PluginHash' => Digest::SHA256.hexdigest(File.read(GEN_PLUGIN_FILENAME))
  }
  flat_args = args.map {|key,val| "-var #{key}=#{val}"}.join ' '
  sh "rocker build #{flat_args}"
  # goes inside the image so it's cached but we want to view this in source control
  sh "docker run --rm -i -u root -v #{Dir.pwd}:/src #{image_tag} cp #{INSTALLED_PLUGINS_FILE} /src/plugins"
end

desc "Pushes out docker image #{image_tag} to the registry"
task :push => :build do
  quay_repo_tag = "quay.io/brady/bswtech-docker-jenkins:#{IMAGE_VERSION}"
  sh "docker tag #{image_tag} #{quay_repo_tag}"
  sh "docker push #{quay_repo_tag}"
end

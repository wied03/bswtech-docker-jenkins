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

desc "Run serverspec tests"
RSpec::Core::RakeTask.new(:spec => [:build, :test_user])

JENKINS_VERSION = '2.73.3-1.1'
JAVA_VERSION = '1.8.0.121-0.b13.el7_3'
GIT_VERSION = '1.8.3.1-6.el7_2.1'
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

# Read by Jenkins repo's script that downloads plugins+deps
GEN_PLUGIN_FILENAME = 'plugins/install_plugins.txt'

task :generate_plugin_list do
  plugins = {
    'build-timeout' => '1.18', # Standard Jenkins
    'docker-workflow' => '1.12', # CloudBees Docker Pipeline
    'credentials' => '2.1.14', # Core credentials plugin
    'credentials-binding' => '1.12', # Allow use of creds in environment variables/pipeline steps
    'email-ext' => '2.57.2', # better email extensions
    'git' => '3.3.1',
    'workflow-aggregator' => '2.5', # the actual core pipeline plugin
    # We have no direct dependency on workflow-job, usually Pipeline takes care of it.
    # Problem is workflow-job 2.13 is the latest and it requires Jenkins 2.62
    'workflow-job' => '2.12.1',
    'pipeline-graph-analysis' => '1.4',
    'ssh-agent' => '1.15', # We use this for core-ansible for SSH credentials
    'timestamper' => '1.8.8', # Base jenkins package, adds them to console output
    'ws-cleanup' => '0.33', # Workspace cleanup
    'antisamy-markup-formatter' => '1.5', # OWASP HTML sanitizer for text fields, standard Jenkins
    'saml' => '0.14', # Authenticate via SAML
    'role-strategy' => '2.5.0', # Best authorization setup available
    'matrix-auth' => '1.7', # Undeclared dependency of role-strategy
    'ec2' => '1.36',
    'jira' => '2.3.1',
    # Needed to trigger multibranch pipelines from Bitbucket
    'cloudbees-bitbucket-branch-source' => '2.1.2'
  }
  # Will be read by shell script (plugins/install-plugins/sh)
  File.write(GEN_PLUGIN_FILENAME, plugins.map {|plugin, version| "#{plugin}:#{version}" }.join("\n"))
end

JENKINS_BIN_DIR='/usr/lib/jenkins'
INSTALLED_PLUGINS_FILE=File.join(JENKINS_BIN_DIR, 'installed_plugins.txt')
desc "Builds Docker image #{image_tag}"
task :build => [:plugin_manager_override, :generate_plugin_list] do
  # not using docker COPY, so need to force changes
  resources_hash = FileList['resources/**'].inject do |exist, file|
    Digest::SHA256.hexdigest(Digest::SHA256.hexdigest(exist)+File.read(file))
  end
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
    'PluginHash' => Digest::SHA256.hexdigest(File.read(GEN_PLUGIN_FILENAME)),
    'ResourcesHash' => resources_hash
  }
  flat_args = args.map {|key,val| "-var #{key}=#{val}"}.join ' '
  begin
    # SELinux causes problems when trying to use the Rocker MOUNT directive
    sh 'setenforce 0' unless ON_MAC
    sh "rocker build #{flat_args}"
    # goes inside the image so it's cached but we want to view this in source control
    sh "docker run --rm -i -u root -v #{Dir.pwd}:/src #{image_tag} cp #{INSTALLED_PLUGINS_FILE} /src/plugins"
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

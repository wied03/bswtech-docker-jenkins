require 'rake'
require 'rspec/core/rake_task'
require 'digest'
# Needs to be before requires. more obvious path than the Rails' standard this library uses
HASHES_FILE = ENV['secure_headers_generated_hashes_file'] = 'content_sec_policy/hashes.yml'
require 'secure_headers'
load 'tasks/tasks.rake'
require_relative 'app/attribute_parser'

task :default => [:build, :spec]

JENKINS_GID = ENV['JENKINS_GID'] = '1002'
JENKINS_UID = ENV['JENKINS_UID'] = '1002'
TEST_VOL_DIR = ENV['TEST_VOL_DIR'] = File.join(Dir.pwd, 'jenkins_test_volume')

ON_MAC = RUBY_PLATFORM.include?('darwin')

task :clean_test_volume do
  rm_rf TEST_VOL_DIR
  mkdir TEST_VOL_DIR
  next unless Gem::Platform.local.os == 'linux'
  puts 'Creating/changing ownership of test volume'
  chown JENKINS_UID,
        nil,
        TEST_VOL_DIR
end

task :setup_test_volume => :clean_test_volume do
  # New stuff in 2.107.1 doesn't yet work right with JIRA plugin, so we test that
  # we whitelist serialization appropriately (see jenkins.sh)
  jira_file = File.join(TEST_VOL_DIR, 'hudson.plugins.jira.JiraProjectProperty.xml')
  File.write jira_file, "<?xml version='1.0' encoding='UTF-8'?>
    <hudson.plugins.jira.JiraProjectProperty_-DescriptorImpl plugin=\"jira@2.4.2\">
      <sites>
        <hudson.plugins.jira.JiraSite>
          <url>https://somejirahost.bswtechconsulting.com/</url>
          <useHTTPAuth>false</useHTTPAuth>
          <userName>jenkins</userName>
          <password>somepassword</password>
          <supportsWikiStyleComment>true</supportsWikiStyleComment>
          <recordScmChanges>false</recordScmChanges>
          <updateJiraIssueForAllStatus>false</updateJiraIssueForAllStatus>
          <timeout>10</timeout>
          <dateTimePattern></dateTimePattern>
          <appendChangeTimestamp>false</appendChangeTimestamp>
        </hudson.plugins.jira.JiraSite>
      </sites>
    </hudson.plugins.jira.JiraProjectProperty_-DescriptorImpl>"
end

desc 'Run serverspec tests with actual container'
RSpec::Core::RakeTask.new(:spec => [:build, :setup_test_volume]) do |task|
  formatter = lambda do |type|
    "--format #{type}"
  end
  file_formatter = lambda do |type, file|
    "#{formatter[type]} --out #{file}"
  end
  task.rspec_opts = [
    formatter['progress'],
    file_formatter['RspecJunitFormatter', File.join(ENV['JUNIT_REPORT_PATH'], 'rspec.xml')]
  ].join(' ') if ENV['GENERATE_REPORTS'] == 'true'
end

JENKINS_VERSION = '2.107.1-1.1'
JAVA_VERSION = '1.8.0.161-0.b14.el7_4'
GIT_VERSION = '1.8.3.1-12.el7_4'
MINOR_VERSION = ENV['MINOR_VERSION'] || '1'
# Drop the RPM subrelease when we build our image
VERSION_NO_SUBRELEASE = Gem::Version.new(JENKINS_VERSION).release
IMAGE_VERSION = "#{VERSION_NO_SUBRELEASE}.#{MINOR_VERSION}"
ENV['IMAGE_TAG'] = image_tag = "bswtech/bswtech-docker-jenkins:#{IMAGE_VERSION}"

TMPFS_FLAGS = "uid=#{JENKINS_UID},gid=#{JENKINS_GID}"
desc 'Run the actual container for manual testing'
task :test_run => [:build, :setup_test_volume] do
  at_exit {
    sh 'docker rm -f jenkins'
  }

  sh "docker run -v #{TEST_VOL_DIR}:/var/jenkins_home:Z --cap-drop=all --read-only --tmpfs=/usr/share/tomcat/work --tmpfs=/var/cache/tomcat:#{TMPFS_FLAGS},exec --tmpfs=/run --tmpfs=/tmp:exec --user #{JENKINS_UID}:#{JENKINS_GID} -P --name jenkins #{image_tag}"
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

execute_plugin_command = lambda do |command|
  Dir.chdir('plugins') do
    Bundler.with_clean_env do
      sh "JENKINS_VERSION=#{VERSION_NO_SUBRELEASE} #{command}"
    end
  end
end

GEN_PLUGIN_FILENAME = 'plugins/Gemfile.lock'
desc 'Fetch plugins using GEM/Bundler wrapper'
task :fetch_plugins do
  execute_plugin_command['jenkins_bundle_install']
end

get_plugin_name = lambda do |jenkins|
  "jenkins-plugin-proxy-#{jenkins}"
end

desc 'Does a bundle update to upgrade a single plugin based on Gemfury sources'
task :upgrade_plugin_conservative, [:plugin_name] do |_, args|
  plugin_name = args[:plugin_name]
  fail 'Must provided a plugin name!' unless plugin_name
  execute_plugin_command["bundle update --conservative #{get_plugin_name[plugin_name]}"]
end

desc 'Does a bundle update to upgrade a single plugin based on Gemfury sources'
task :upgrade_plugin_liberal, [:plugin_name] do |_, args|
  plugin_name = args[:plugin_name]
  fail 'Must provided a plugin name!' unless plugin_name
  execute_plugin_command["bundle update #{get_plugin_name[plugin_name]}"]
end

desc 'Does a bundle update to upgrade a single plugin, removes local index before updating'
task :upgrade_plugin_new, [:plugin_names] do |_, args|
  plugin_names = args[:plugin_names].split(':')
  fail 'Must provided a plugin name!' unless plugin_names
  plugin_names = plugin_names.map {|p| get_plugin_name[p]}
  execute_plugin_command["jenkins_bundle_update #{plugin_names.join(' ')}"]
end

desc 'Get new Jenkins shim for bundler'
task :upgrade_jenkins_plugin_shim do
  execute_plugin_command["jenkins_bundle_update #{get_plugin_name['jenkins-core']}"]
end

desc 'Dumps image version this build is for'
task :dump_version do
  puts IMAGE_VERSION
end

desc 'Display plugin dependency graph'
task :display_plugins do
  execute_plugin_command['bundle list']
end

desc 'Seed NEW Gemfury/local GEM index with derived GEMs from Jenkins Update Center'
task :seed_plugins do
  execute_plugin_command['jenkins_seed']
end

# TODO: Use this when we actually need it (not yet)
#desc 'Writes a content security policy setting for the hudson.model.DirectoryBrowserSupport.CSP system property'
task :build_csp => :'secure_headers:generate_hashes' do
  config = SecureHeaders::Configuration.new do |config|
    config.csp = {
      default_src: %w('none'),
      sandbox: %w(allow-scripts),
      img_src: %w('self')
    }
    hashes = YAML.load_file HASHES_FILE
    script_tag_hashes = hashes['scripts'].map {|_, hash_list| hash_list}.flatten
    script_hashes = script_tag_hashes + AttributeParser.js_file_hashes
    config.csp[:script_src] = script_hashes.uniq
    style_tag_hashes = hashes['styles'].map {|_, hash_list| hash_list}.flatten
    style_hashes = style_tag_hashes + AttributeParser.inline_style_hashes + AttributeParser.css_file_hashes
    config.csp[:style_src] = style_hashes.uniq
  end
  config.validate_config!
  csp = SecureHeaders::ContentSecurityPolicy.new config.csp
  puts "System.setProperty(\"hudson.model.DirectoryBrowserSupport.CSP\", \"#{csp.value}\")"
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

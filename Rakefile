require 'rake'
require 'rspec/core/rake_task'
require 'digest'
require 'zip'
require 'bundler'
require 'yaml'
require 'base64'

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
  if ENV['SKIP_TEST_VOLUME_CLEAN']
    puts 'Skipping test volume clean'
    next
  end
  rm_rf TEST_VOL_DIR
  mkdir TEST_VOL_DIR
  next unless Gem::Platform.local.os == 'linux'
  puts 'Creating/changing ownership of test volume'
  chown JENKINS_UID,
        nil,
        TEST_VOL_DIR
end

task :setup_test_volume => :clean_test_volume do
  if ENV['PRESERVE_VOLUME'] == '1'
    puts 'Skipping test vol clean due to PRESERVE_VOLUME'
    next
  end
  # New stuff in 2.107.1 doesn't yet work right with JIRA plugin, so we test that
  # we whitelist serialization appropriately (jenkins.sh <= commit 6e97e673a9f8712177a25e5c354408aa96ded433 had to workaround this)
  # has since been fixed in JIRA plugin but this should sniff out the problem if it comes back
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
    formatter['documentation'],
    file_formatter['RspecJunitFormatter', File.join(ENV['JUNIT_REPORT_PATH'], 'rspec.xml')]
  ].join(' ') if ENV['GENERATE_REPORTS'] == 'true'
end

JENKINS_VERSION = '2.204.1-1.1'
JAVA_VERSION = '1.8.0.232.b09-0.el7_7'
GIT_VERSION = '1.8.3.1-20.el7'
MINOR_VERSION = ENV['MINOR_VERSION'] || '1'
# Drop the RPM subrelease when we build our image
VERSION_NO_SUBRELEASE = Gem::Version.new(JENKINS_VERSION).release
IMAGE_VERSION = "#{VERSION_NO_SUBRELEASE}.#{MINOR_VERSION}"
ENV['IMAGE_TAG'] = image_tag = "bswtech/bswtech-docker-jenkins:#{IMAGE_VERSION}"
PLUGIN_MANAGER_PATH = 'plugins/modified_plugin_manager'
JAR_PATH = File.join(PLUGIN_MANAGER_PATH, 'build', 'libs', "bswtech-docker-jenkins-#{VERSION_NO_SUBRELEASE}.jar")

SECRET_FILE = 'test_secrets/somesecret'
JSON_FILE = ENV['GCE_SVC_ACCOUNT_JSON_FILE']
file SECRET_FILE => [JSON_FILE] do
  encoded = Base64.encode64(File.read(JSON_FILE))
  mkdir_p File.expand_path('..', SECRET_FILE)
  File.write SECRET_FILE, encoded
end

TMPFS_FLAGS = "uid=#{JENKINS_UID},gid=#{JENKINS_GID}"
desc 'Run the actual container for manual testing'
task :test_run => [:build, :setup_test_volume, SECRET_FILE] do
  at_exit {
    sh 'docker rm -f jenkins'
  }
  volumes = [
    "#{TEST_VOL_DIR}:/var/jenkins_home:Z",
    "#{Dir.pwd}/test_secrets:/run/test_secrets:Z"
  ]
  additional = ENV['additional_test_volumes']&.split(',') || []
  volumes += additional
  flat_volumes = volumes.map do |vol|
    "-v #{vol}"
  end.join(' ')
  port = ENV['JENKINS_PORT']
  sh "docker run #{flat_volumes} #{port ? "-p #{port}:8080" : '-P'} -e SECRETS=/run/test_secrets --cap-drop=all --read-only --tmpfs=/run --tmpfs=/tmp:exec --user #{JENKINS_UID}:#{JENKINS_GID} --name jenkins #{image_tag}"
end

JAVA_SOURCE = FileList[File.join(PLUGIN_MANAGER_PATH, '**/*')].exclude(File.join(PLUGIN_MANAGER_PATH, 'build', '**/*'))
desc 'Builds the plugin manager for read-only Jenkins plugins'
file JAR_PATH => JAVA_SOURCE do
  Dir.chdir(PLUGIN_MANAGER_PATH) do
    sh "./gradlew --no-daemon -Pversion=#{VERSION_NO_SUBRELEASE} clean build"
  end
end

PLUGIN_GEM_WRAPPER_PATH = 'plugins/rubygems_wrapper'
# this comes from the GEM
PLUGIN_FINAL_DIRECTORY = File.join(PLUGIN_GEM_WRAPPER_PATH, 'plugins_final')
PLUGIN_GEMFILE = File.join(PLUGIN_GEM_WRAPPER_PATH, 'Gemfile')
PLUGIN_GEMFILE_LOCK = PLUGIN_GEMFILE + '.lock'

execute_plugin_command = lambda do |command|
  Dir.chdir(PLUGIN_GEM_WRAPPER_PATH) do
    Bundler.with_unbundled_env do
      sh "JENKINS_VERSION=#{VERSION_NO_SUBRELEASE} #{command}"
    end
  end
end

JAVA_JENKINS_PLUGINS = []
desc 'Fetch plugins using GEM/Bundler wrapper'
file PLUGIN_FINAL_DIRECTORY => [PLUGIN_GEMFILE] + JAVA_JENKINS_PLUGINS do
  execute_plugin_command['jenkins_bundle_install']
  JAVA_JENKINS_PLUGINS.each do |plugin|
    destination = File.join(PLUGIN_FINAL_DIRECTORY, File.basename(plugin))
    zip_file = Zip::File.open(plugin)
    mkdir_p destination
    zip_file.each do |file|
      full_path = File.join(destination, file.name)
      puts "Extracting #{full_path}"
      file.extract(full_path)
    end
  end
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

desc 'Fetch new versions of plugins and liberally update'
task :upgrade_plugins do
  execute_plugin_command["jenkins_bundle_update"]
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

desc 'Validates CASC'
task :validate_casc do
  FileList['resources/casc/*'].each do |yml|
    puts "Validating #{yml}"
    file = File.read yml
    parsed = YAML.load file
    puts "Parsed as"
    pp parsed
  end
end

JENKINS_BIN_DIR = '/usr/lib/jenkins'
desc "Builds Docker image #{image_tag}"
task :build => [:validate_casc, JAR_PATH, PLUGIN_FINAL_DIRECTORY] do
  nss_upgrade_packages = %w(util softokn tools softokn-freebl sysinit).map do |suffix|
    "nss-#{suffix}"
  end
  upgrade_packages = (%w(nss) + nss_upgrade_packages).join ' '
  args = {
    'ImageVersion' => IMAGE_VERSION,
    'JenkinsVersion' => JENKINS_VERSION,
    'JavaPackage' => "java-1.8.0-openjdk-#{JAVA_VERSION}", # can't use java headless because hudson.util.ChartUtil needs some X11 stuff
    'GitPackage' => "git-#{GIT_VERSION}",
    'JenkinsBinDir' => JENKINS_BIN_DIR,
    'PluginJarPath' => JAR_PATH,
    'UPGRADE_PACKAGES' => "\"#{upgrade_packages}\""
  }
  flat_args = args.map {|key, val| "--build-arg #{key}=#{val}"}.join ' '
  begin
    # SELinux causes problems when trying to use the Rocker MOUNT directive
    sh 'setenforce 0' unless ON_MAC
    sh "docker build --label Version=#{IMAGE_VERSION} -t #{image_tag} #{flat_args} ."
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

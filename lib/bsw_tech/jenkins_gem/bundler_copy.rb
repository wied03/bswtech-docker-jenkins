require 'bundler'
require 'yaml'
require 'fileutils'

dir = ENV['PLUGIN_DEST_DIR']
fail 'Specify PLUGIN_DEST_DIR env variable' unless dir && !dir.empty?
FileUtils.rm_rf dir
FileUtils.mkdir_p dir

Bundler.load.specs.select do |s|
  s.name.start_with?('jenkins') && !s.name.include?('jenkins-core')
end.each do |s|
  hash = YAML.load s.to_yaml
  jenkins_name = hash.metadata['jenkins_name']
  source_path = s.full_gem_path
  dest_path = File.join(dir, "#{jenkins_name}.hpi")
  puts "Coping '#{jenkins_name}' from #{source_path} to #{dest_path}"
  FileUtils.cp_r(source_path, dest_path)
end

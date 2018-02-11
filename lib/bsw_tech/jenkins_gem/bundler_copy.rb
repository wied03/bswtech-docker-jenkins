require 'bundler'
require 'yaml'
require 'fileutils'

# TODO: Move all of this to a separate library
# TODO: Reactivate Gemfury
# TODO: When gem hpi files are added, sign it and upload to Gemfury
# TODO: Provide a separate one off command to download an hpi and upload a built gem for that to fury. can use previous code that interprets manifest
# TODO: Use bins for current shell script
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
  FileUtils.cp_r(source_path, dest_path)
  # Jenkins insists on this timestamp file
  FileUtils.touch File.join(dest_path, '.timestamp2')
end

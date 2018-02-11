require 'bundler'
require 'yaml'
require 'fileutils'
require 'bsw_tech/jenkins_gem/update_json_parser'

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
  s.name.start_with?('jenkins') && !s.name.include?(BswTech::JenkinsGem::UpdateJsonParser::JENKINS_CORE_PACKAGE)
end.each do |s|
  # It's odd this is called to_yaml, but it does in fact load the gemspec that we can retrieve metadata from
  gem_spec = YAML.load s.to_yaml
  jenkins_name = gem_spec.metadata[BswTech::JenkinsGem::UpdateJsonParser::METADATA_JENKINS_NAME]
  source_path = s.full_gem_path
  dest_path = File.join(dir, "#{jenkins_name}.hpi")
  FileUtils.cp_r(source_path, dest_path)
  # Jenkins insists on this timestamp file
  FileUtils.touch File.join(dest_path, '.timestamp2')
end

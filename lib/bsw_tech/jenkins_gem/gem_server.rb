require 'sinatra'
require 'net/http'
require 'rubygems/package'
require 'rubygems/indexer'
require 'fileutils'
require 'bsw_tech/jenkins_gem/update_json_parser'
require 'bsw_tech/jenkins_gem/jenkins_list_fetcher'
require 'zip'
require 'tmpdir'
require 'digest'
require 'tempfile'

index_dir = ENV['INDEX_DIRECTORY']
raise 'Set the INDEX_DIRECTORY variable' unless index_dir
# Indexer looks here
gems_dir = File.join(index_dir, 'gems')

def fetch(uri_str, limit = 10)
  # You should choose a better exception.
  raise ArgumentError, 'too many HTTP redirects' if limit == 0

  response = Net::HTTP.get_response(URI(uri_str))
  case response
  when Net::HTTPSuccess then
    response
  when Net::HTTPRedirection then
    location = response['location']
    fetch(location, limit - 1)
  else
    response.value
  end
end

get '/quick/Marshal.4.8/:rz_file' do |rz_file|
  File.open(File.join(index_dir, 'quick', 'Marshal.4.8', rz_file), 'rb')
end

get '/specs.4.8.gz' do
  build_index(index_dir, gems_dir)
  File.open(File.join(index_dir, 'specs.4.8.gz'), 'rb')
end

get '/gems/:gem_filename' do |gem_filename|
  path = File.absolute_path(File.join(gems_dir, gem_filename))
  next [404, "Unable to find gem #{gem_filename}"] unless File.exists? path
  gem = ::Gem::Package.new path
  spec = gem.spec
  unless spec.name.include?(BswTech::JenkinsGem::UpdateJsonParser::JENKINS_CORE_PACKAGE)
    add_hpi_to_gem gem, path unless spec.files.any?
  end
  File.open(path, 'rb')
end

# TODO: Somewhere, use the Jenkins metadata JSON to verify if any security problems exist

def add_hpi_to_gem(gem, index_gem_path)
  spec = gem.spec
  metadata = spec.metadata
  jenkins_name = metadata[BswTech::JenkinsGem::UpdateJsonParser::METADATA_JENKINS_NAME]
  jenkins_version = metadata[BswTech::JenkinsGem::UpdateJsonParser::METADATA_JENKINS_VERSION]
  url = "https://updates.jenkins.io/download/plugins/#{jenkins_name}/#{jenkins_version}/#{jenkins_name}.hpi"
  hpi_response = begin
    fetch(url)
  rescue StandardError => e
    puts "Problem fetching HPI from Jenkins - #{e}"
    raise e
  end
  return [404, hpi_response.body] unless hpi_response.is_a? Net::HTTPSuccess
  temp_file = Tempfile.new('.zip')
  begin
    temp_file.write hpi_response.body
    temp_file.rewind
    signature = Digest::SHA1.file temp_file
    temp_file.rewind
    expected_sha = metadata[BswTech::JenkinsGem::UpdateJsonParser::METADATA_SHA1]
    actual = signature.base64digest
    fail "ZIP failed SHA1 check. Expected '#{expected_sha}', got '#{actual}'" unless actual  == expected_sha
    begin
      Dir.mktmpdir 'gem_temp_dir' do |local_temp_path|
        gem.extract_files local_temp_path
        Zip::File.open(temp_file) do |zip_file|
          zip_file.each do |entry|
            full_path = File.join(local_temp_path, entry.name)
            entry.extract(full_path)
          end
        end
        Dir.chdir(local_temp_path) do
          spec.files = Dir['**/*']
          built_gem_path = ::Gem::Package.build spec
          puts "Copying #{built_gem_path} to #{index_gem_path}"
          FileUtils.copy built_gem_path, index_gem_path
        end
      end
    rescue StandardError => e
      puts "zip/GEM error #{e}"
      raise e
    end
  ensure
    temp_file.close
    temp_file.unlink
  end
end

# TODO: ETag based index expire?
def build_index(index_dir, gems_dir)
  if File.exist?(index_dir)
    return
  end
  puts "Fetching Jenkins plugin list..."

  jenkins_versions = BswTech::JenkinsGem::JenkinsListFetcher.get_available_versions

  parser = begin
    update_response = fetch('http://updates.jenkins-ci.org/update-center.json').body
    BswTech::JenkinsGem::UpdateJsonParser.new(update_response, jenkins_versions)
  rescue StandardError => e
    puts "Problem fetching Jenkins info #{e}"
    raise e
  end

  gem_list = parser.gem_listing
  FileUtils.rm_rf index_dir
  FileUtils.mkdir_p index_dir
  FileUtils.mkdir_p gems_dir
  puts "Fetched #{gem_list.length} GEM specs from Jenkins, Writing GEM skeletons to #{gems_dir}"
  Dir.chdir(gems_dir) do
    with_quiet_gem do
      gem_list.each do |gemspec|
        begin
          ::Gem::Package.build gemspec
        rescue StandardError => e
          puts "Error while writing GEM for #{gemspec.name}, #{e}"
          raise e
        end
      end
    end
  end
  Gem::Indexer.new(index_dir,
                   { build_modern: true }).generate_index
end

def with_quiet_gem
  current_ui = Gem::DefaultUserInteraction.ui
  Gem::DefaultUserInteraction.ui = Gem::SilentUI.new
  yield
ensure
  Gem::DefaultUserInteraction.ui = current_ui
end

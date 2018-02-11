require 'sinatra'
require 'net/http'
require 'rubygems/package'
require 'rubygems/indexer'
require 'fileutils'
require 'bsw_tech/jenkins_gem/update_json_parser'

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
    warn "redirected to #{location}"
    fetch(location, limit - 1)
  else
    response.value
  end
end

get '/quick/Marshal.4.8/:rz_file' do |rz_file|
  build_index(index_dir, gems_dir)
  File.open(File.join(index_dir, 'quick', 'Marshal.4.8', rz_file), 'rb')
end

get '/specs.4.8.gz' do
  build_index(index_dir, gems_dir)
  File.open(File.join(index_dir, 'specs.4.8.gz'), 'rb')
end

get '/gems/:gem_filename' do |gem_filename|
  path = File.join(gems_dir, gem_filename)
  next [404, "Unable to find gem #{gem_filename}"] unless File.exists? path
  gem = ::Gem::Package.new path
  spec = gem.spec
  puts "found gem #{spec.name}, metadata #{spec.metadata}"
  # TODO: This will work. Fetch the HPI file from Jenkins' server and rebuild the GEM with the HPI inside it
  # TODO: Add a core Jenkins fake GEM. Populate stuff based on it
  # TODO: ETag based index expire?
  # TODO: Somewhere, use the Jenkins metadata JSON to verify if any security problems exist
  nil
end

def build_index(index_dir, gems_dir)
  if File.exist?(index_dir)
    return
  end
  puts "Fetching Jenkins plugin list..."

  parser = begin
    update_response = fetch('http://updates.jenkins-ci.org/update-center.json').body
    BswTech::JenkinsGem::UpdateJsonParser.new(update_response)
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

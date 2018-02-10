require 'sinatra'
require 'net/http'
require 'rubygems/package'
require 'rubygems/indexer'
require 'fileutils'
require 'bsw_tech/jenkins_gem/update_json_parser'

index_dir = ENV['INDEX_DIRECTORY']
raise 'Set the INDEX_DIRECTORY variable' unless index_dir

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

get '/specs.4.8.gz' do
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
  # Indexer looks here
  gems_dir = File.join(index_dir, 'gems')
  FileUtils.mkdir_p gems_dir
  puts "Fetched #{gem_list.length} GEM specs from Jenkins, Writing GEM skeletons to #{gems_dir}"
  Dir.chdir(gems_dir) do
    gem_list.each do |gemspec|
      begin
        ::Gem::Package.build gemspec
      rescue StandardError => e
        puts "Error while writing GEM for #{gemspec.name}, #{e}"
        raise e
      end
    end
  end
  Gem::Indexer.new(index_dir,
                   { build_modern: true }).generate_index
  File.open(File.join(index_dir, 'specs.4.8.gz'), 'rb')
end

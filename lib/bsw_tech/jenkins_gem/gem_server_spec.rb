require 'spec_helper'
require 'rack/test'
index_directory = File.join(File.dirname(__FILE__), 'test_gem_index')
ENV['INDEX_DIRECTORY'] = index_directory
require 'bsw_tech/jenkins_gem/gem_server'

describe 'GEM Server' do
  before(:context) {FileUtils.rm_rf index_directory}
  after(:context) {FileUtils.rm_rf index_directory}
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'specs' do
    subject do
      response = get '/specs.4.8.gz'
      Marshal.load(Gem.gunzip(response.body))
    end

    its(:length) {is_expected.to eq 1440}
  end

  describe 'individual GEM' do
    subject {get '/quick/Marshal.4.8/jenkins-plugin-proxy-git-3.7.0.gemspec.rz'}

    its(:ok?) {is_expected.to eq true}
  end
end

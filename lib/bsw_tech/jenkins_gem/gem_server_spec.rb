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

    its(:length) {is_expected.to eq 1516}
  end

  describe 'individual GEM metadata' do
    subject {get '/quick/Marshal.4.8/jenkins-plugin-proxy-git-3.7.0.gemspec.rz'}

    its(:ok?) {is_expected.to eq true}
  end

  describe 'individual GEMs' do
    describe 'Jenkins core' do
      subject(:response) {get '/gems/jenkins-plugin-proxy-jenkins-core-2.89.3.gem'}

      its(:ok?) {is_expected.to eq true}

      describe 'GEM' do
        subject do
          package = ::Gem::Package.new StringIO.new(response.body)
          package.spec
        end

        its(:name) {is_expected.to eq 'jenkins-plugin-proxy-jenkins-core'}
      end
    end

    context 'not found' do
      subject(:response) {get '/gems/foobar.gem'}

      its(:ok?) {is_expected.to eq false}
      its(:status) {is_expected.to eq 404}
    end
    pending 'write it'
  end
end

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
    before {get '/specs.4.8.gz'}

    subject(:gem) do
      expect(response.ok?).to eq true
      package = ::Gem::Package.new StringIO.new(response.body)
      package.spec
    end

    describe 'Jenkins core' do
      let(:response) {get '/gems/jenkins-plugin-proxy-jenkins-core-2.89.3.gem'}

      describe 'GEM' do
        its(:name) {is_expected.to eq 'jenkins-plugin-proxy-jenkins-core'}
        its(:files) {is_expected.to eq []}
      end
    end

    context 'not found' do
      subject(:response) {get '/gems/foobar.gem'}

      its(:ok?) {is_expected.to eq false}
      its(:status) {is_expected.to eq 404}
    end

    context 'found' do
      let(:response) {get '/gems/jenkins-plugin-proxy-apache-httpcomponents-client-4-api-4.5.3.2.1.gem'}
      its(:name) {is_expected.to eq 'jenkins-plugin-proxy-apache-httpcomponents-client-4-api'}

      it 'has files' do
        expect(gem.files.length).to eq 10
        expect(gem.files[0]).to eq 'META-INF/MANIFEST.MF'
      end
    end
  end
end

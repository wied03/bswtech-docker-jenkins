require 'spec_helper'
require 'rack/test'
require 'bsw_tech/jenkins_gem/gem_server'

fdescribe 'GEM Server' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'specs' do
    subject do
      response = get '/specs.4.8.gz'
      Marshal.load(Gem.gunzip(response.body))
    end

    its(:length) { is_expected.to eq 1440 }
  end
end

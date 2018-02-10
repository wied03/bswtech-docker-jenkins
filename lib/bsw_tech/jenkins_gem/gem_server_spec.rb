require 'spec_helper'
require 'rack/test'
require 'bsw_tech/jenkins_gem/gem_server'

describe 'GEM Server' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe 'specs' do
    subject do
      response = get '/specs.4.8.gz'
      Marshal.load(Gem.gunzip(response.body))
    end

    # TODO: Need to somehow get all Jenkins plugins here
    it {is_expected.to eq [
                            ['jenkins-plugin-proxy-git',
                             # Version does not matter
                             Gem::Version.new('9.9.9'),
                             'ruby']
                          ]}
  end
end

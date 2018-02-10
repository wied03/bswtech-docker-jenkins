require 'spec_helper'
require 'rack/test'
require 'bsw_tech/jenkins_gem/gem_server'

describe 'GEM Server' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  context 'GEM found' do
    subject {get '/'}

    its(:ok?) {is_expected.to eq true}
    its(:body) {is_expected.to eq 'foobar'}

    pending 'write this'
  end
end

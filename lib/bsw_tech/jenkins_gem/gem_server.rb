require 'sinatra'

get '/specs.4.8.gz' do
  list = [
    ['jenkins-plugin-proxy-git',
     # Version does not matter
     Gem::Version.new('9.9.9'),
     'ruby']
  ]
  marshalled = Marshal.dump(list)
  Gem.gzip(marshalled)
end

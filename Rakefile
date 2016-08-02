require 'rake'
require 'rspec/core/rake_task'

task :default => :spec

if ENV['GENERATE_REPORTS'] == 'true'
  require 'ci/reporter/rake/rspec'
  task :spec => 'ci:setup:rspec'
end

desc "Run serverspec tests"
RSpec::Core::RakeTask.new(:spec)

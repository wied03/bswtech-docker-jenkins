require 'rspec/core'
require 'rspec/its'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.fail_if_no_examples = true
  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
end

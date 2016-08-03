require 'spec_helper'

describe 'Jenkins image test' do
  # Could use sleep here, but maybe it's better to use the retryable GEM
  describe command('curl -I http://localhost:8080') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  pending 'volumes, run as user, permissions'
end

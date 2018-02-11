require 'net/http'

module BswTech
  module JenkinsGem
    module JenkinsListFetcher
      def self.get_available_versions
        response = Net::HTTP.get_response(URI('http://mirrors.jenkins.io/war-stable/'))
        response.body.scan(/href="(\S+)\/"/)
          .map {|groups| groups[0]}
          .reject {|version| version == 'latest'}
      end
    end
  end
end

require 'zip'
require 'bsw_tech/jenkins_gem/manifest_parser'

module BswTech
  module JenkinsGem
    class HpiParser
      attr_reader :gem_spec

      def initialize(zip_io)
        Zip::File.open(zip_io) do |zip_file|
          manifest = zip_file.find {|entry| entry.name.upcase == 'META-INF/MANIFEST.MF'}
          unless manifest
            file_names = zip_file.map {|entry| entry.name}
            fail "Unable to find manifest in files #{file_names}"
          end
          raw_string = manifest.get_input_stream.read
          # get CRLF without this
          manifest = raw_string.encode(raw_string.encoding, universal_newline: true)
          parser = BswTech::JenkinsGem::ManifestParser.new(manifest)
          @gem_spec = parser.gem_spec
        end
      end
    end
  end
end

module BswTech
  module JenkinsGem
    class ManifestParser
      attr_reader :gem_spec
      SEPARATOR = ': '

      def initialize(manifest_contents)
        properties = Hash[manifest_contents
                            .split("\n")
                            .map do |property_line|
          parts = property_line.split SEPARATOR
          [parts[0], parts[1..-1].join(SEPARATOR)]
        end]
        @gem_spec = Gem::Specification.new do |s|
          s.description = properties['Specification-Title']
        end
      end
    end
  end
end

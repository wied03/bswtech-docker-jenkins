module BswTech
  module JenkinsGem
    class ManifestParser
      attr_reader :gem_spec
      SEPARATOR = ': '
      PREFIX = 'jenkins-plugin-proxy'

      def initialize(manifest_contents)
        properties = get_prop_hash manifest_contents
        @gem_spec = Gem::Specification.new do |s|
          s.name = "#{PREFIX}-#{properties['Extension-Name']}"
          s.description = properties['Specification-Title']
          s.summary = properties['Long-Name']
          s.version = properties['Plugin-Version']
          s.homepage = properties['Url']
          s.authors = properties['Plugin-Developers'].split(',')
        end
      end

      private

      def get_prop_hash(manifest_contents)
        consistent_lines = manifest_contents.split("\n").inject([]) do |line_array, current_line|
          previous_line = line_array.pop
          # Manifest lines are wrapped at a fixed boundary
          new_lines = if current_line.start_with? ' '
                        # Trim off the extra space
                        [previous_line + current_line[1..-1]]
                      else
                        [previous_line, current_line]
                      end
          line_array + new_lines.compact
        end

        Hash[consistent_lines.map do |property_line|
          parts = property_line.split SEPARATOR
          [parts[0], parts[1..-1].join(SEPARATOR)]
        end]
      end
    end
  end
end

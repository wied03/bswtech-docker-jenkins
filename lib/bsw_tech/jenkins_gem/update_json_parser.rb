module BswTech
  module JenkinsGem
    class UpdateJsonParser
      attr_reader :gem_spec
      SEPARATOR = ': '
      PREFIX = 'jenkins-plugin-proxy'

      def initialize(manifest_contents)
        fail 'Manifest contents is required' unless manifest_contents && !manifest_contents.empty?
        properties = get_prop_hash manifest_contents
        @gem_spec = Gem::Specification.new do |s|
          s.name = "#{PREFIX}-#{properties['Extension-Name']}"
          s.description = properties['Specification-Title']
          s.summary = properties['Long-Name']
          s.version = properties['Plugin-Version']
          s.homepage = properties['Url']
          s.authors = properties['Plugin-Developers'].split(',')
          properties['Plugin-Dependencies'].split(',').each do |dependency_string|
            name_version, props = dependency_string.split ';'
            props = props ? Hash[props.split(',').map {|kv| kv.split(':=')}] : {}
            next if props['resolution'] == 'optional'
            name, version = name_version.split(':')
            s.add_runtime_dependency "#{PREFIX}-#{name}",
                                     version
          end
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

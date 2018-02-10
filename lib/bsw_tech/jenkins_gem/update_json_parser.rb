module BswTech
  module JenkinsGem
    class UpdateJsonParser
      SEPARATOR = ': '
      PREFIX = 'jenkins-plugin-proxy'

      attr_reader :gem_listing

      def initialize(file_blob)
        fail 'File blob contents is required' unless file_blob && !file_blob.empty?
        metadata = get_hash file_blob
        @gem_listing = metadata['plugins'].map do |plugin_name, info|
          Gem::Specification.new do |s|
            s.name = "#{PREFIX}-#{plugin_name}"
            s.description = info['excerpt']
            s.version = info['version']
            s.homepage = info['wiki']
            s.authors = info['developers'].map {|dev| dev['email']}
            info['dependencies'].each do |dependency|
              next if dependency['optional']
              s.add_runtime_dependency "#{PREFIX}-#{dependency['name']}",
                                       dependency['version']
            end
          end
        end
      end

      private

      def get_hash(file_blob)
        trailing_end_index = file_blob.rindex(');')
        only_json = file_blob[0..trailing_end_index - 1].gsub('updateCenter.post(', '')
        JSON.parse only_json
      end
    end
  end
end

module BswTech
  module JenkinsGem
    class UpdateJsonParser
      SEPARATOR = ': '
      PREFIX = 'jenkins-plugin-proxy'
      DEPENDENCY_REMAPS = {
        # For some reason, Jenkins seems to reference invalid dependency versions sometimes
        'matrix-project' => {
          '1.7.1' => '1.12'
        }
      }

      attr_reader :gem_listing

      def initialize(file_blob)
        fail 'File blob contents is required' unless file_blob && !file_blob.empty?
        metadata = get_hash file_blob
        @gem_listing = metadata['plugins'].map do |plugin_name, info|
          begin
            Gem::Specification.new do |s|
              s.name = get_name(plugin_name)
              excerpt = info['excerpt'].gsub('TODO:', '')
              s.summary = excerpt
              jenkins_version = info['version']
              s.version = format_version(jenkins_version)
              s.metadata = {
                'jenkins_version' => jenkins_version,
                'jenkins_name' => plugin_name,
                'sha1' => info['sha1']
              }
              s.homepage = info['wiki']
              developers = info['developers'].map do |dev|
                dev['email'] || dev['developerId']
              end
              s.authors = developers.any? ? developers : ['unknown']
              info['dependencies'].each do |dependency|
                add_dependency dependency, s
              end
              add_core_jenkins(info['requiredCore'], s)
            end
          rescue StandardError => e
            puts "Error while parsing plugin '#{plugin_name}' info #{info}"
            raise e
          end
        end
      end

      private

      def add_core_jenkins(version,
                           gem_spec)
        gem_spec.add_runtime_dependency get_name('jenkins-core'),
                                        ">= #{version}"
      end

      def get_name(package)
        "#{PREFIX}-#{package}"
      end

      def add_dependency(dependency, gem_spec)
        return if dependency['optional']
        candidate_version = dependency['version']
        dependency_name = dependency['name']
        remap = DEPENDENCY_REMAPS[dependency_name]
        if remap
          new_version = remap[candidate_version]
          candidate_version = new_version if new_version
        end
        candidate_version = format_version candidate_version
        gem_spec.add_runtime_dependency get_name(dependency_name),
                                        ">= #{candidate_version}"
      end

      def format_version(jenkins_number)
        # + is not a legal character in GEM versions but we can change it back later
        jenkins_number.gsub('+', '.')
          .gsub('-', '.') # Rubygems treats dash as a pre-release version
      end

      def get_hash(file_blob)
        trailing_end_index = file_blob.rindex(');')
        only_json = file_blob[0..trailing_end_index - 1].gsub('updateCenter.post(', '')
        JSON.parse only_json
      end
    end
  end
end

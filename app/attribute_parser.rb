module AttributeParser
  include SecureHeaders::HashHelper

  class << self
    def get_inline_style_hashes(filename)
      text = File.read filename
      hashes = []
      text.scan(/style="(.*?)"/) do
        inline_style = Regexp.last_match.captures.last
        hashes << hash_source(inline_style)
      end
      hashes
    end

    def css_file_hashes
      results = []
      Dir.glob("app/{views,templates}/**/*.css") do |filename|
        puts "Getting style sheet file hashes from #{filename}"
        results << hash_source(File.read(filename))
      end
      results
    end

    def js_file_hashes
      results = []
      Dir.glob("app/{views,templates}/**/*.js") do |filename|
        puts "Getting JS file hashes from #{filename}"
        results << hash_source(File.read(filename))
      end
      results
    end

    def inline_style_hashes
      results = []
      Dir.glob("app/{views,templates}/**/*.{erb,mustache}") do |filename|
        puts "Getting inline style hashes from #{filename}"
        results.concat get_inline_style_hashes(filename)
      end
      results
    end
  end
end

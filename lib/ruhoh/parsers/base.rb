class Ruhoh
  module Parsers

    class Base
      
      def initialize(ruhoh)
        @ruhoh = ruhoh
      end
      
      def registered_name
        self.class.registered_name
      end
      
      def namespace
        if self.class.class_variable_defined?(:@@namespace)
          self.class.class_variable_get(:@@namespace)
        else
          Ruhoh::Utils.underscore(registered_name)
        end
      end
      
      # Default paths to the 3 levels of the cascade.
      def paths
        [@ruhoh.paths.system, @ruhoh.paths.base, @ruhoh.paths.theme]
      end

      # Generate all data resources for this data endpoint.
      # Returns dictionary of all data resources.
      #
      # Generate a single data resource as identified by `id`
      # Returns dictionary containing the singular data resource.
      def generate(id=nil)
        dict = {}
        self.files(id).each { |pointer|
          dict.merge!(modeler.new(@ruhoh, pointer).generate)
        }
        Ruhoh::Utils.report(self.registered_name, dict, [])
        dict
      end

      # Collect all files (as mapped by data resources) for this data endpoint.
      # Each resource can have 3 file references, one per each cascade level.
      # The file hashes are collected in order 
      # so they will overwrite eachother if found.
      # Returns Array of file data hashes.
      # 
      # id - (Optional) String or Array.
      # Collect all files for a single data resource.
      # Can be many files due to the cascade.
      # Returns Array of file hashes.
      def files(id=nil)
        a = []
        Array(self.paths).each do |path|
          namespaced_path = File.join(path, namespace)
          next unless File.directory?(namespaced_path)
          FileUtils.cd(namespaced_path) {
            file_array = (id ? Array(id) : Dir[self.glob])
            file_array.each { |id|
              next unless File.exist? id
              if self.respond_to? :is_valid_page?
                next unless self.is_valid_page?(id)
              end
              a << {
                "id" => id,
                "realpath" => File.realpath(id),
                "parser" => registered_name,
              }
            }
          }
        end
        a
      end

      # Proxy to the single modeler class for this parser.
      def modeler
        self.class.const_get(:Modeler)
      end

      def self.registered_name
        self.name.split("::").last
      end
      
    end
    
    module Page
      
      FMregex = /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
      
      def content
        self.parse_page_file['content']
      end

      def parse_page_file
        raise "File not found: #{@pointer['realpath']}" unless File.exist?(@pointer['realpath'])

        page = File.open(@pointer['realpath'], 'r:UTF-8') {|f| f.read }

        front_matter = page.match(FMregex)
        if front_matter
          data = YAML.load(front_matter[0].gsub(/---\n/, "")) || {}
        else
          data = {}
        end

        {
          "data" => data,
          "content" => page.gsub(FMregex, '')
        }
      rescue Psych::SyntaxError => e
        Ruhoh.log.error("ERROR in #{path}: #{e.message}")
        nil
      end
      
    end
    
    class BaseModeler

      def initialize(ruhoh, pointer)
        @ruhoh = ruhoh
        # Automatically set which parser type is being used.
        b = Ruhoh::Utils.constantize(self.class.name.chomp("::Modeler"))
        pointer["type"] = b.registered_name
        @pointer = pointer
      end
    end

  end
end
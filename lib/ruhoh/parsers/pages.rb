class Ruhoh
  module Parsers
    class Pages < Base
      
      def glob
        "**/*.*"
      end

      def is_valid_page?(filepath)
        return false if FileTest.directory?(filepath)
        return false if ['.'].include? filepath[0]
        @ruhoh.config.pages_exclude.each {|regex| return false if filepath =~ regex }
        true
      end


      class Modeler < BaseModeler
        include Page
        
        # Generate this filepath
        # Returns data to be registered to the database
        def generate
          parsed_page     = self.parse_page_file
          data            = parsed_page['data']
          data['pointer'] = @pointer
          data['id']      = @pointer['id']
          data['url']     = self.permalink(data)
          data['title']   = data['title'] || self.to_title
          data['layout']  = @ruhoh.config.pages_layout unless data['layout']

          # Register this route for the previewer
          @ruhoh.db.routes[data['url']] = @pointer

          {
            "#{@pointer['id']}" => data
          }
        end
      
        def to_title
          name = File.basename( @pointer['id'], File.extname(@pointer['id']) )
          name = @pointer['id'].split('/')[-2] if name == 'index' && !@pointer['id'].index('/').nil?
          name.gsub(/[^\p{Word}+]/u, ' ').gsub(/\b\w/){$&.upcase}
        end
    
        # Build the permalink for the given page.
        # Only recognize extensions registered from a 'convertable' module.
        # This means 'non-convertable' extensions should pass-through.
        #
        # Returns [String] the permalink for this page.
        def permalink(page)
          ext = File.extname(page['id'])
          name = page['id'].gsub(Regexp.new("#{ext}$"), '')
          ext = '.html' if Ruhoh::Converter.extensions.include?(ext)
          url = name.split('/').map {|p| Ruhoh::Urls.to_url_slug(p) }.join('/')
          url = "#{url}#{ext}".gsub(/index.html$/, '')
          if page['permalink'] == 'pretty' || @ruhoh.config.pages_permalink == 'pretty'
            url = url.gsub(/\.html$/, '')
          end
        
          url = '/' if url.empty?
          @ruhoh.to_url(url)
        end
      end

    end
  end
end
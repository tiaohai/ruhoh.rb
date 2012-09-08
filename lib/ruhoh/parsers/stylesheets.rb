class Ruhoh
  module Parsers
    # Collect all registered stylesheets.
    # Themes explicitly define which stylesheets to load via theme.yml.
    # All styling is managed by the theme, including widget styles.
    # If the theme provides widget stylesheets they will load automatically.
    # theme.yml may also specify an explicit widget stylesheet to load.
    module Stylesheets
      @ruhoh = nil
      # Generates mappings to all registered stylesheets.
      # Returns Hash with layout names as keys and Array of asset Objects as values
      def self.generate(ruhoh)
        @ruhoh = ruhoh
        assets = self.theme_stylesheets
        assets[Ruhoh.names.widgets] = self.widget_stylesheets
        assets
      end
      
      # Create mappings for stylesheets registered to the theme layouts.
      # Themes register stylesheets relative to their layouts.
      # Returns Hash with layout names as keys and Array of asset Objects as values.
      def self.theme_stylesheets
        return {} unless @ruhoh.db.theme_config[Ruhoh.names.stylesheets].is_a? Hash
        assets = {}
        @ruhoh.db.theme_config[Ruhoh.names.stylesheets].each do |key, value|
          next if key == Ruhoh.names.widgets # Widgets are handled separately.
          assets[key] = Array(value).map { |v|
            url = (v =~ /^(http:|https:)?\/\//i) ? v : "#{@ruhoh.urls.theme_stylesheets}/#{v}"
            {
              "url" => url,
              "id" => File.join(@ruhoh.paths.theme_stylesheets, v)
            }
          }
        end
        
        assets
      end
      
      # Create mappings for stylesheets registered to a given widget.
      # A theme may provide widget stylesheets which will load automatically,
      # provided they adhere to the default naming rules.
      # Themes may also specify an explicit widget stylesheet to load.
      # 
      # Returns Array of asset objects.
      def self.widget_stylesheets
        assets = []
        @ruhoh.db.widgets.each_key do |name|
          default_name = "#{name}.css"
          stylesheet = @ruhoh.db.theme_config[Ruhoh.names.stylesheets][Ruhoh.names.widgets][name] rescue default_name
          stylesheet ||=  default_name
          file = File.join(@ruhoh.paths.theme_widgets, name, Ruhoh.names.stylesheets, stylesheet)
          next unless File.exists?(file)
          assets << {
            "url" => [@ruhoh.urls.theme_widgets, name, Ruhoh.names.stylesheets, stylesheet].join('/'),
            "id" => file
          }
        end

        assets
      end
      
    end #Stylesheets
  end #Parsers
end #Ruhoh
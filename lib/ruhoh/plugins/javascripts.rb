module Ruhoh::Plugins
  # Collect all the javascripts.
  # Themes explicitly define which javascripts to load via theme.yml.
  # Additionally, widgets may register javascript dependencies, which are resolved here.
  class Javascripts < Base

    def config
      hash = @ruhoh.db.config("theme")["javascripts"]
      hash.is_a?(Hash) ? hash : {}
    end
    
    # Generates mappings to all registered javascripts.
    # Returns Hash with layout names as keys and Array of asset Objects as values
    def generate
      return {} if config.empty?
      theme_path = paths.select{|h| h["name"] == "theme"}.first["path"]
      assets = {}
      config.each do |key, value|
        next if key == "widgets" # Widgets are handled separately.
        assets[key] = Array(value).map { |v|
          {
            "url" => url(v),
            "id" => File.join(theme_path, "javascripts", v)
          }
        }
      end
      
      assets
    end

    def url(node)
      (node =~ /^(http:|https:)?\/\//i) ? node : "#{@ruhoh.urls.theme_javascripts}/#{node}"
    end
    
    # Notes:
    #   The automatic script inclusion is currently handled within the widget parser.
    #   This differs from the auto-stylesheet inclusion relative to themes, 
    #   which is handled in the stylesheet parser.
    #   Make sure there are some standards with this.
    def widget_javascripts
      assets = []
      @ruhoh.db.widgets.each_value do |widget|
        next unless widget["javascripts"]
        assets += Array(widget["javascripts"]).map {|path|
          {
            "url" => [@ruhoh.urls.widgets, widget['name'], "javascripts", path].join('/'),
            "id"  => File.join(@ruhoh.paths.widgets, widget['name'], "javascripts", path)
          }
        }
      end
      
      assets
    end
    
  end
end
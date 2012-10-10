class Ruhoh
  module Plugins

    class Site < Base

      def generate
        Ruhoh::Utils.parse_yaml_file(@ruhoh.paths.site_data) || {}
      end

    end
  end
end
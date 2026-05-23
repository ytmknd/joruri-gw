require_relative "font_lib"
module PikiDoc
  module Bundles
    class Font
      include PluginAdapter
      include FontLib
      def initialize()

      end
    end
  end
end

require_relative "font_lib"
module PikiDoc
  module Bundles
    class Fonts
      include PluginAdapter
      include FontLib
      def initialize()

      end
    end
  end
end

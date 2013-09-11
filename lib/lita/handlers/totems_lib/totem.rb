require 'celluloid'
module Lita::Handlers
  module TotemsLib
    class Totem
      include Celluloid

      attr_accessor :name

      def initialize(name)
        @name = name
      end
    end
  end
end
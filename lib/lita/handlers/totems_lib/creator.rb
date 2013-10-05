require 'celluloid'
require_relative 'totem'

module Lita::Handlers
  module TotemsLib

    class Creator
      include Celluloid

      attr_reader :totems
      attr_reader :totem_owners

      def initialize(totems, totem_owners)
        @totems       = totems
        @totem_owners = totem_owners
      end

      def create_if_doesnt_exist(totem_name)
        if totems[totem_name].present?
          false
        else
          totems[totem_name] = Totem.new(totem_name, totem_owners)
          true
        end
      end

      def destroy_if_exists(totem_name)
        totem = totems[totem_name]
        if totem.present?
          totems.delete(totem_name)
          totem_owners[totem.owner].delete(totem) if totem.owner.present?
          true
        else
          false
        end
      end

    end

  end
end
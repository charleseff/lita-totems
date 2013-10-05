require 'celluloid'
module Lita::Handlers
  module TotemsLib
    class Totem
      include Celluloid

      attr_accessor :name
      attr_reader :totem_owners

      def initialize(name, totem_owners)
        @name         = name
        @totem_owners = totem_owners
      end

      # the user at the head of the queue is actually the user with the totem
      def queue
        @queue ||= []
      end

      def owner
        queue[0]
      end

      def add(user)

        totem_owners[user] << self if queue.empty?
        queue << user

        queue.size
      end
    end
  end
end
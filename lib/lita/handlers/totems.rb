require "lita"
require 'active_support/core_ext/integer/inflections'

module Lita
  module Handlers
    class Totems < Handler
      def self.route_regex(action_capture_group)
        %r{
        ^totems?\s+
        (#{action_capture_group})\s+
        (?<totem>\w+)
        }x
      end

      route(route_regex("add|join|take|queue"), :add,
            help: {
                'totems add TOTEM' => "Adds yourself to the TOTEM queue, or assigns yourself to the TOTEM if it's unassigned"
            })

      route(route_regex("yield|finish|leave|done|complete|remove"), :yield,
            help: {
                'totems yield TOTEM' => 'Yields the TOTEM.  If you are in the queue for the totem, leaves the queue.'
            })

      route(route_regex("create"), :create,
            help: {
                'totems create TOTEM' => 'Creates a new totem TOTEM.'
            })

      route(route_regex("destroy|delete"), :destroy,
            help: {
                'totems destroy TOTEM' => 'Destroys totem TOTEM.'
            })

      route(
          %r{#{route_regex("kick").source}
        (
          \s+(?<user>\w+)
        )?
        }x,
          :kick,
          help: {
              'totems kick TOTEM' => 'Kicks the user currently in possession of the TOTEM off.',
              'totems kick TOTEM USER' => 'Kicks the specified user from the totem.'
          })

      def destroy(response)
        totem = response.match_data[:totem]
        if redis.exists("totem:#{totem}")
          redis.del("totem:#{totem}")
          redis.del("list:#{totem}")
          response.reply(%{Destroyed totem "#{totem}".})
        else
          response.reply(%{Error: totem "#{totem}" doesn't exist.})
        end
      end

      def create(response)
        totem = response.match_data[:totem]

        if redis.exists("totem:#{totem}")
          response.reply %{Error: totem "#{totem}" already exists.}
        else
          redis.set("totem:#{totem}", 1)
          response.reply %{Created totem "#{totem}".}
        end

      end

      def add(response)
        totem = response.match_data[:totem]
        unless redis.exists("totem:#{totem}")
          response.reply %{Error: there is no totem "#{totem}".}
          return
        end

        queue_size = redis.lpush("list:#{totem}", response.user.id)
        if queue_size == 1
          response.reply(%{#{response.user.name}, you now have totem "#{totem}".})
        else
          in_line = queue_size - 1
          response.reply(%{#{response.user.name}, you are #{in_line.ordinalize} in line for totem "#{totem}".})
        end
      end

    end

    Lita.register_handler(Totems)
  end
end

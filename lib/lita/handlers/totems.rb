require "lita"

module Lita
  module Handlers
    class Totems < Handler
      TOTEMS_PREFIX_REGEX = /^totems?\s+/.source
      route(
        %r{
        #{TOTEMS_PREFIX_REGEX}
        (add|join|take|queue)\s+
        (?<totem>\w+)
        }x,
        :add,
        help: {
          'totems add TOTEM' => "Adds yourself to the TOTEM queue, or assigns yourself to the TOTEM if it's unassigned"
        })

      route(
        %r{
        #{TOTEMS_PREFIX_REGEX}
        (yield|finish|leave|done|complete|remove)\s+
        (?<totem>\w+)
        }x,
        :yield,
        help: {
          'totems yield TOTEM' => 'Yields the TOTEM.  If you are in the queue for the totem, leaves the queue.'
        })

      route(
        %r{
        #{TOTEMS_PREFIX_REGEX}
        (create)\s+
        (?<totem>\w+)
        }x,
        :create,
        help: {
          'totems create TOTEM' => 'Creates a new totem TOTEM.'
        })

      route(
        %r{
        #{TOTEMS_PREFIX_REGEX}
        (destroy|delete)\s+
        (?<totem>\w+)
        }x,
        :destroy,
        help: {
          'totems destroy TOTEM' => 'Destroys totem TOTEM.'
        })

      route(
        %r{
        #{TOTEMS_PREFIX_REGEX}
        (kick)\s+
        (?<totem>\w+)
        (
          \s+(?<user>\w+)
        )?
        }x,
        :kick,
        help: {
          'totems kick TOTEM'      => 'Kicks the user currently in possession of the TOTEM off.',
          'totems kick TOTEM USER' => 'Kicks the specified user from the totem.'
        })

      def destroy(response)
        totem = response[:totem]
        if redis.exists("totem:#{totem}")
          redis.del("totem:#{totem}")
          redis.del("list:#{totem}")
          response.reply("Destroyed totem #{totem}.")
        else
          response.reply("Error: totem #{totem} doesn't exist.")
        end
      end

      def create(response)
        totem = response[:totem]
        if redis.exists("totem:#{totem}")
          response.reply "Error: totem #{totem} already exists."
        else
          redis.set("totem:#{totem}", 1)
          response.reply "Created totem #{totem}."
        end

      end


    end

    Lita.register_handler(Totems)
  end
end

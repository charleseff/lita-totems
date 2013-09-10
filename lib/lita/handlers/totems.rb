require "lita"
require 'active_support/core_ext/integer/inflections'
require 'active_support/core_ext/object/blank'
require 'redis-semaphore'

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

      route(
        %r{
        ^totems?\s+
        (yield|finish|leave|done|complete|remove)
        (\s+(?<totem>\w+))?
        }x,
        :yield,
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

      route(route_regex("kick"),
            :kick,
            help: {
              'totems kick TOTEM' => 'Kicks the user currently in possession of the TOTEM off.',
            })


      route(
        #/^totems?(\s+info(\s+(?<totem>\w+))?)?$/,
        %r{
            ^totems?
            (\s+info?
              (\s+(?<totem>\w+))?
            )?
            $
            }x,
            :info,
            help: {
              'totems info'       => "Shows info of all totems queues",
              'totems info TOTEM' => 'Shows info of just one totem'
            })

      def destroy(response)
        totem = response.match_data[:totem]
        if redis.exists("totem/#{totem}")
          redis.del("totem/#{totem}")
          redis.del("totem/#{totem}/list")
          redis.srem("totems", totem)
          owning_user_id = redis.get("totem/#{totem}/owning_user_id")
          redis.srem("user/#{owning_user_id}/totems", totem) if owning_user_id
          response.reply(%{Destroyed totem "#{totem}".})
        else
          response.reply(%{Error: totem "#{totem}" doesn't exist.})
        end
      end

      def create(response)
        totem = response.match_data[:totem]

        if redis.exists("totem/#{totem}")
          response.reply %{Error: totem "#{totem}" already exists.}
        else
          redis.set("totem/#{totem}", 1)
          redis.sadd("totems", totem)
          response.reply %{Created totem "#{totem}".}
        end

      end

      def add(response)
        totem = response.match_data[:totem]
        unless redis.exists("totem/#{totem}")
          response.reply %{Error: there is no totem "#{totem}".}
          return
        end

        user_id = response.user.id

        token_acquired = false
        queue_size     = nil
        Redis::Semaphore.new("totem/#{totem}", redis: redis).lock do
          if redis.llen("totem/#{totem}/list") == 0 && redis.get("totem/#{totem}/owning_user_id").blank?
            # take it:
            token_acquired = true
            redis.set("totem/#{totem}/owning_user_id", user_id)
          else
            # queue:
            queue_size = redis.lpush("totem/#{totem}/list", user_id)
          end
        end

        if token_acquired
          redis.sadd("user/#{user_id}/totems", totem)
          response.reply(%{#{response.user.name}, you now have totem "#{totem}".})
        else
          response.reply(%{#{response.user.name}, you are #{queue_size.ordinalize} in line for totem "#{totem}".})
        end

      end

      def yield(response)
        user_id              = response.user.id
        totems_owned_by_user = redis.smembers("user/#{user_id}/totems")
        if totems_owned_by_user.empty?
          response.reply "Error: You do not have any totems to yield."
        elsif totems_owned_by_user.size == 1
          yield_totem(totems_owned_by_user[0], user_id, response)
        else # totems count > 1
          totem_specified = response.match_data[:totem]
          if totem_specified
            if totems_owned_by_user.include?(totem_specified)
              yield_totem(totem_specified, user_id, response)
            else
              response.reply %{Error: You don't own the "#{totem_specified}" totem.}
            end
          else
            response.reply "You must specify a totem to yield.  Totems you own: #{totems_owned_by_user.sort}"
          end
        end
      end

      def kick(response)
        totem = response.match_data[:totem]
        unless redis.exists("totem/#{totem}")
          response.reply %{Error: there is no totem "#{totem}".}
          return
        end

        past_owning_user_id = redis.get("totem/#{totem}/owning_user_id")
        if past_owning_user_id.nil?
          response.reply %{Error: Nobody owns totem "#{totem}" so you can't kick someone from it.}
          return
        end

        redis.srem("user/#{past_owning_user_id}/totems", totem)
        robot.send_messages(User.new(past_owning_user_id), %{You have been kicked from totem "#{totem}".})
        next_user_id = redis.lpop("totem/#{totem}/list")
        redis.set("totem/#{totem}/owning_user_id", next_user_id)
        if next_user_id
          redis.sadd("user/#{next_user_id}/totems", totem)
          robot.send_messages(User.new(next_user_id), %{You are now in possession of totem "#{totem}".})
        end

      end

      def info(response)
        totem = response.match_data[:totem]
        resp  = if totem.present?
                  list_users_print(totem)
                else
                  r = "Totems:\n"
                  redis.smembers("totems").each do |totem|
                    r += "- #{totem}\n"
                    r += list_users_print(totem, '  ')
                  end
                  r
                end
        response.reply resp
      end

      private
      def list_users_print(totem, prefix='')
        str      = ''
        first_id = redis.get("totem/#{totem}/owning_user_id")
        if first_id
          str  += "#{prefix}1. User id #{first_id}\n"
          rest = redis.lrange("totem/#{totem}/list", 0, -1)
          rest.each_with_index do |user_id, index|
            str += "#{prefix}#{index+2}. User id #{user_id}\n"
          end
        end
        str
      end

      def yield_totem(totem, user_id, response)
        redis.srem("user/#{user_id}/totems", totem)
        next_user_id = redis.lpop("totem/#{totem}/list")
        if next_user_id
          redis.sadd("user/#{next_user_id}/totems", totem)
          robot.send_messages(User.new(next_user_id), %{You are now in possession of totem "#{totem}."})
          response.reply "You have yielded the totem to #{next_user_id}."
        else
          response.reply %{You have yielded the "#{totem}" totem.}
        end
        redis.set("totem/#{totem}/owning_user_id", next_user_id)
      end
    end

    Lita.register_handler(Totems)
  end
end

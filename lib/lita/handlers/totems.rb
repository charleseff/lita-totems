require "lita"
require 'active_support/core_ext/integer/inflections'
require 'active_support/core_ext/object/blank'
require 'lita/handlers/totems_lib/totem'
require 'lita/handlers/totems_lib/creator'
require 'set'

module Lita
  module Handlers
    # a new Handler class shouldn't be created for each call, is it?
    class Totems < Handler

      def self.route_regex(action_capture_group)
        %r{
        ^totems?\s+
        (#{action_capture_group})\s+
        (?<totem>\w+)
        }x
      end

      # a Map from totem name to Totem object
      # not to be altered by this class
      def self.totems
        @totems ||= {}
      end

      def self.creator
        @creator = TotemsLib::Creator.new(totems, totem_owners)
      end

      # a Map from Users to Sets of Totems
      def self.totem_owners
        @totem_owners = Hash.new(Set[])
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
        totem_name = response.match_data[:totem]
        if self.class.creator.destroy_if_exists(totem_name)
          response.reply(%{Destroyed totem "#{totem_name}".})
        else
          response.reply(%{Error: totem "#{totem_name}" doesn't exist.})
        end
      end

      def create(response)
        totem_name = response.match_data[:totem]

        if self.class.creator.create_if_doesnt_exist(totem_name)
          response.reply %{Created totem "#{totem_name}".}
        else
          response.reply %{Error: totem "#{totem_name}" already exists.}
        end

      end

      def add(response)
        totem_name = response.match_data[:totem]
        totem      = totems[totem_name]

        if totem.nil?
          response.reply %{Error: there is no totem "#{totem}".}
          return
        end

        user       = response.user
        queue_size = totem.add(user)
        if queue_size == 1
          response.reply(%{#{user.name}, you now have totem "#{totem_name}".})
        else
          response.reply(%{#{user.name}, you are #{(queue_size-1).ordinalize} in line for totem "#{totem_name}".})
        end

      end

      def add_bak(response)
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
        totem_param = response.match_data[:totem]
        resp        = if totem_param.present?
                        list_users_print(totem_param)
                      else
                        users_cache = new_users_cache
                        r           = "Totems:\n"
                        redis.smembers("totems").each do |totem|
                          r += "- #{totem}\n"
                          r += list_users_print(totem, '  ', users_cache)
                        end
                        r
                      end
        response.reply resp
      end

      private
      def new_users_cache
        Hash.new { |h, id| h[id] = Lita::User.find_by_id(id) }
      end

      def list_users_print(totem, prefix='', users_cache=new_users_cache)
        str      = ''
        first_id = redis.get("totem/#{totem}/owning_user_id")
        if first_id

          str  += "#{prefix}1. #{users_cache[first_id].name}\n"
          rest = redis.lrange("totem/#{totem}/list", 0, -1)
          rest.each_with_index do |user_id, index|
            str += "#{prefix}#{index+2}. #{users_cache[user_id].name}\n"
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

      def totems
        self.class.totems
      end

    end

    Lita.register_handler(Totems)
  end
end

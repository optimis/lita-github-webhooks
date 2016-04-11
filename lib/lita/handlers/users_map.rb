module Lita
  module Handlers
    class MappingUsers < Handler

      route(/^add\suser\smapping\s([^\s]+)\s=>\s(.+)$/, :add_user_mapping, command: true, help: {"add user mapping GITHUB => SLACK" => "Add user mapping to redis for GitHub Web hooks"})

      def add_user_mapping response
        message = message_title
        response.matches.each do |match|
          if match.size == 2
            webhook_redis.hset "webhook:user", match[0], match[1]
            message << "\n>_%s `%s`_" % match
          end
        end

        response.reply(message)
      end

      route(/^get\suser\smapping$/, :get_user_mapping, command: true, help: {"get user mapping" => "Get user list from redis"})

      def get_user_mapping response
        message = message_title
        webhook_redis.hgetall("webhook:user").each do |k,v|
          message << "\n>_%s `%s`_" % [k,v]
        end

        response.reply(message)
      end

      route(/^delete\suser\s([^\s]+)$/, :delete_user, command: true, help: {"delete user GITHUB" => "Delete user mapping from redis for GitHub Web hooks"})

      def delete_user response
        message = ""
        response.matches.each do |match|
          if match.size == 1
            message << "\n>_%s `%s`_ been deleted." % [match[0], webhook_redis.hget("webhook:user", match[0])]
            webhook_redis.hdel "webhook:user", match[0]
          end
        end

        response.reply(message)
      end

      def message_title
        "*%s `%s`*" % ["Github username", "Slack mention name"]
      end

      private
        def webhook_redis
          redis.namespace = "handlers:github_webhooks"
          redis
        end

      Lita.register_handler(self)
    end
  end
end

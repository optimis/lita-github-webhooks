module Lita
  module Handlers
    class Notification < Handler

      route(/^add\srepo\s(.+)$/, :add_notification_list, command: true, help: {"add repo REPO:BRANCH" => "Add which repo and branch need notifier everyone for GitHub Web hooks"})

      def add_notification_list response
        message = message_title
        response.matches.each do |match|
          webhook_redis.zadd "webhook:list", 1, match[0]
          message << "\n>_#{match[0]}_"
        end

        response.reply(message)
      end

      route(/^get\srepo\slist$/, :get_notification_list, command: true, help: {"get repo list" => "Get repository list from redis"})

      def get_notification_list response
        message = message_title
        webhook_redis.zrange("webhook:list", 0, -1).each do |item|
          message << "\n>#{item}"
        end

        response.reply(message)
      end

      route(/^delete\srepo\s([^\s]+)$/, :delete_notification, command: true, help: {"delete repo REPO:BRANCH" => "Delete repository from list for GitHub Web hooks"})

      def delete_notification response
        message = ""
        response.matches.each do |match|
          if match.size == 1
            message << "\n>_#{match[0]}_ been deleted."
            webhook_redis.zrem "webhook:list", match[0]
          end
        end

        response.reply(message)
      end

      def message_title
        "*Repository:Branch*"
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

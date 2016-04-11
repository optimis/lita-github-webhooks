module Lita
  module Handlers
    class GithubWebhooks < Lita::Extensions::GitHubWebHooksCore::HookReceiver

      config :notification_list, default: []
      config :channel
      config :color, default: "#008B8B"

      http.post "/github-webhooks", :receive_hook

      def self.name
        "GithubWebhooks"
      end

      [:push].each do |event_type|
        on event_type, event_type
      end

      def push payload
        info = get_information_from payload
        message = message_generater info

        if need_notifier_all? info
          message[0].merge!(author_name: "@channel")
          send_messages message
        else
          user = redis.hget("webhook:user", info[:head][:committer])

          if user
            send_messages_with user, message
          else
            message[0].merge!(author_name: "@channel Is anyone know who is #{info[:head][:committer]}?")
            send_messages message
          end
        end
      end

      private
        def need_notifier_all? info
          result = false
          repo = "#{info[:project]}:#{info[:branch]}"
          if info[:forced]
            branch = info[:branch] + ":force"
            result = config.notification_list.include? branch
          end

          result or config.notification_list.include? info[:branch] or redis.zrange('webhook:list', 0, -1).include? repo
        end

        def get_information_from payload
          commits = []
          payload["commits"].each do |commit|
            commits << {
              id: git_id(commit),
              message: commit["message"],
              committer: commit["committer"]["username"]
            }
          end
          {
            created: payload["created"],
            deleted: payload["deleted"],
            forced: payload["forced"],
            project: payload["repository"]["name"],
            project_link: link_to(payload["repository"]["url"], payload["repository"]["name"]),
            branch: payload["ref"].gsub(/^refs\/heads\//,""),
            compare: payload["compare"],
            head: {
              id: git_id(payload["head_commit"]),
              message: payload["head_commit"]["message"],
              committer: payload["head_commit"]["committer"]["username"]
            },
            commits: commits
          }
        end

        def message_generater info
          text = ""

          if info[:commits].size > 1
            committers = []
            info[:commits].each do |commit|
              text << "\n#{commit_info(commit)}"
              committers << commit[:committer] until committers.include? commit[:committer]
            end

            pretext = "#{link_to(info[:compare], "#{info[:commits].size} new commits")} by #{info[:head][:committer]}"

            if committers.size == 1
              pretext << ":"
            elsif committers.size == 2
              pretext << "and 1 other:"
            elsif committers.size > 2
              pretext << "and #{committers.size-1} others:"
            end
          else
            pretext = "1 new commit by #{info[:head][:committer]}:"
            text = commit_info(info[:head])
          end

          if info[:forced]
            pretext = "[#{info[:project_link]}] Branch \"#{info[:branch]}\" was force-pushed by #{info[:head][:committer]}"
          else
            pretext = "[#{info[:project]}:#{info[:branch]}] " << pretext
          end
          messages = [{
            color: config.color,
            pretext: pretext,
            text: text
          }]
        end

        def commit_info commit
          COMMITS % commit
        end

        def git_id commit
          link_to commit["url"], commit["id"][0..6]
        end

        def link_to url, text
          "<#{url}|#{text}>"
        end

        def send_messages messages
          room = Lita::Room.find_by_name config.channel
          robot.chat_service.send_attachments(room, messages)
        end

        def send_messages_with user, messages
          user = Lita::User.find_by_mention_name user
          robot.chat_service.send_attachments(user, messages)
        end

      Lita.register_handler(self)
    end
  end
end

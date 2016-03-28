module Lita
  module Handlers
    class GithubWebhooks < Lita::Extensions::GitHubWebHooksCore::HookReceiver

      config :directory, default: "/tmp"

      def self.name
        "GithubWebhooks"
      end

      [:pull_request, :status, :push, :deployment,
       :deployment_status, :commit_comment,
       :issue_comment, :pull_request_review_comment].each do |event_type|
         on event_type, :store
       end

      def logger
        Lita.logger
      end

      def store payload
        path = path payload
        logger.debug("Payload received: storing in #{path}")
        FileUtils.mkdir_p config.directory
        File.open(path, 'w') { |file| file.write(JSON.generate(payload)) }
      end

      def path payload
        File.join(config.directory, filename(payload))
      end

      def filename payload
        "#{Time.now.to_i}-#{payload[:event_type]}.json"
      end

      http.post "/github-webhooks", :receive_hook

      Lita.register_handler(self)
    end
  end
end

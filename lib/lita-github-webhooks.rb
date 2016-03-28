require "lita"
require 'lita-github-web-hooks-core'

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita/handlers/github_webhooks"

Lita::Handlers::GithubWebhooks.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)

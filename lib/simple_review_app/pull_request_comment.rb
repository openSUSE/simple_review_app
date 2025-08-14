# frozen_string_literal: true

require 'active_model'
require_relative 'logger'

class SimpleReviewApp
  class PullRequestComment
    include ActiveModel::Model
    include Logger

    attr_accessor :client, :pull_request, :body
    attr_writer :logger

    def self.after_deploy(review_app)
      new(client: review_app.client,
          pull_request: review_app.pull_request,
          body: "Review app will appear here: #{review_app.url}",
          logger: review_app.logger).submit
    end

    def submit
      logger.info("Create comment on PR##{pull_request.number}")
      client.add_comment(
        pull_request.full_repository_name,
        pull_request.number,
        body
      )
    end
  end
end

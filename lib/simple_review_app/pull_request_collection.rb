# frozen_string_literal: true

require 'octokit'
require 'active_model'
require_relative 'logger'
require_relative 'pull_request'

class SimpleReviewApp
  class PullRequestCollection
    include ActiveModel::Model
    include Logger

    attr_accessor :repository, :organization, :labels, :client
    attr_writer :logger

    def all
      logger.info "Fetching pull requests with label '#{labels}' for '#{full_repository_name}'."
      pull_requests
    end

    private

    def pull_requests
      # We have to do roundtrips here as the GitHup API does not support
      # fetching pull requests by their label
      pull_request_numbers.map do |pull_request_number|
        PullRequest.new(
          content: client.pull_request(full_repository_name, pull_request_number.number),
          full_repository_name:,
          logger:
        )
      end
    end

    def pull_request_numbers
      client.list_issues(full_repository_name, labels:).find_all(&:pull_request)
    end

    def full_repository_name
      "#{organization}/#{repository}"
    end
  end
end

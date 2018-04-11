# frozen_string_literal: true

require 'octokit.rb'
require 'active_model'
require './lib/review_lab/logger'
require './lib/review_lab/pull_request'

class ReviewLab
  class PullRequestCollection
    include ActiveModel::Model
    include Logger
    attr_accessor :username, :password, :repository, :organization, :labels
    attr_writer :logger

    def all
      authenticate
      logger.info "Fetching pull requests with label '#{labels}' for '#{full_repository_name}'."
      pull_requests
    end

    private

    def pull_requests
      # We have to do roundtrips here as the GitHup API does not support
      # fetching pull requests by their label
      pull_request_numbers.map do |pull_request_number|
        PullRequest.new(
          content: Octokit.pull_request(full_repository_name, pull_request_number.number),
          logger: logger
        )
      end
    end

    def pull_request_numbers
      Octokit.list_issues(full_repository_name, labels: labels).find_all(&:pull_request)
    end

    def authenticate
      return unless credentials?
      logger.info "Try to authenticate to GitHub with username #{username}."
      Octokit.configure do |c|
        c.login = username
        c.password = password
      end
      logger.info "Successfully authenticated to GitHub with username #{username}."
    end

    def full_repository_name
      "#{organization}/#{repository}"
    end

    def credentials?
      username.present? && password.present?
    end
  end
end

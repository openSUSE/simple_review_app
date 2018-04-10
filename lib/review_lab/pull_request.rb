# frozen_string_literal: true

require 'active_model'
require './lib/review_lab/logger'

class ReviewLab
  class PullRequest
    include ActiveModel::Model
    include Logger
    attr_accessor :content, :logger

    def clone(directory)
      logger.info "Execute '#{clone_command}' in '#{directory}'."
      Dir.mkdir(directory)
      Dir.chdir(directory) do
        `#{clone_command}`
      end
    end

    def user_login
      content.head.user.login
    end

    def branch
      content.head.ref
    end

    private

    def fork_url
      content.head.repo.clone_url
    end

    def clone_command
      "git clone -b #{branch} --single-branch #{fork_url}"
    end
  end
end

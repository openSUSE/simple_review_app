# frozen_string_literal: true

require 'active_model'
require './lib/review_lab/logger'

class ReviewLab
  class PullRequest
    include ActiveModel::Model
    include Logger
    attr_accessor :content
    attr_writer :logger

    def update(directory)
      logger.info('Pull request already exists.')
      return unless changed?(directory)
      logger.info('Pull request changed, updating...')
      fetch_and_reset(directory)
    end

    def clone(directory)
      logger.info "Execute '#{clone_command}' in '#{directory}'."
      Dir.mkdir(directory)
      Dir.chdir(directory) do
        `#{clone_command}`
      end
      logger.info "Successfully cloned into '#{directory}'."
    end

    def user_login
      content.head.user.login
    end

    def branch
      content.head.ref
    end

    private

    def fetch_and_reset(directory)
      Dir.chdir(File.join(directory, project_name)) do
        `git fetch --all`
        `git reset origin/#{branch} --hard`
      end
      logger.info("Successfully updated branch to #{head_sha}")
    end

    def changed?(directory)
      return true if head_sha != cloned_sha(directory)
      logger.info('Pull request did not change, continue...')
      false
    end

    def project_name
      content.head.repo.name
    end

    def cloned_sha(directory)
      Dir.chdir(File.join(directory, project_name)) do
        `git rev-parse HEAD`.chomp
      end
    end

    def head_sha
      content.head.sha
    end

    def fork_url
      content.head.repo.clone_url
    end

    def clone_command
      "git clone -b #{branch} --single-branch #{fork_url}"
    end
  end
end

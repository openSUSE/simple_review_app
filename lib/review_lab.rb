# frozen_string_literal: true

require 'yaml'
require 'active_model'
require './lib/review_lab/review_app'
require './lib/review_lab/pull_request_collection'
require './lib/review_lab/review_app_manager'
require './lib/review_lab/logger'
require 'logger'

class ReviewLab
  include ActiveModel::Model
  include Logger
  attr_accessor :review_app_manager, :config
  attr_writer :logger

  def self.run
    main_instance.run
  end

  def run
    logger.info('Starting review lab.')
    review_app_manager.update(pull_requests)
  rescue StandardError => e
    logger.error(e)
  end

  private

  class << self
    private

    def logger
      @logger ||= ::Logger.new(log_file_path).tap do |log|
        log.level = ::Logger::INFO
      end
    end

    def log_file_path
      File.join(log_directory, 'review_lab.log')
    end

    def log_directory
      log_directory = File.join(review_lab_directory, 'logs').freeze
      return log_directory if File.exist?(log_directory)
      Dir.mkdir(log_directory)
      log_directory
    end

    def config
      @config ||= YAML.load_file(config_path)
    rescue StandardError => e
      msg = "Error loading config file: #{e.message}"
      logger.fatal(msg)
      abort(msg)
    end

    def review_lab_directory
      File.join(File.dirname(__FILE__), '..').freeze
    end

    def config_path
      File.join(review_lab_directory, 'config.yml').freeze
    end

    def working_directory
      File.join(review_lab_directory, 'review_apps').freeze
    end

    def create_working_directory
      return if File.exist?(working_directory)
      msg = "Working directory #{working_directory} does not exist, creating it."
      logger.info(msg)
      Dir.mkdir(working_directory)
    end

    def main_instance
      create_working_directory
      manager = ReviewAppManager.new(
        working_directory: working_directory,
        logger: logger
      )
      @main_instance ||= ReviewLab.new(review_app_manager: manager)
    end
  end

  def pull_requests
    result = PullRequestCollection.new(
      organization: config['github_organization'],
      repository: config['github_repository'],
      labels: config['github_labels'],
      client: client,
      logger: logger
    ).all
    logger.info("Found #{result.count} open pull requests.")
    result
  end

  def credentials?
    config['github_username'].present? && config['github_password'].present?
  end

  def client
    return @client if @client.present?
    if credentials?
      logger.info "Authenticating to GitHub with username #{config['github_username']}."
      @client = Octokit::Client.new(login: config['github_username'], password: config['github_password'])
    else
      logger.info 'Using github API as anonymous user.'
      @client = Octokit::Client.new
    end
  end
end

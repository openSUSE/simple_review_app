# frozen_string_literal: true

require 'yaml'
require './lib/review_lab/review_app'
require './lib/review_lab/pull_request_collection'
require 'logger'

class ReviewLab
  def self.run
    main_instance.run
  end

  def run
    logger.info('Starting review lab.')
    self.running_apps = []
    create_working_directory
    deploy_review_apps
    destroy_review_apps
  rescue StandardError => e
    logger.error(e)
  end

  attr_accessor :running_apps

  private

  class << self
    private

    def main_instance
      @main_instance ||= ReviewLab.new
    end
  end

  def logger
    @logger ||= ::Logger.new(log_file_path).tap do |log|
      log.level = ::Logger::INFO
    end
  end

  def log_file_path
    File.join(log_directory, 'review_lab.log')
  end

  def deploy_review_apps
    pull_requests.each do |pull_request|
      deploy_review_app(pull_request)
    end
  end

  def deploy_review_app(pull_request)
    running_apps << ReviewApp.new(
      pull_request: pull_request,
      project_name: config['github_repository'],
      host: config['host'],
      client: client,
      options: review_app_options,
      logger: logger
    ).deploy
  end

  def review_app_options
    {
      working_directory: working_directory,
      before_script: config['before_script']
    }
  end

  def destroy_review_apps
    orphaned_apps.each do |dir|
      options = { working_directory: working_directory }
      ReviewApp.new(
        name: dir,
        project_name: config['github_repository'],
        options: options,
        logger: logger
      ).destroy
    end
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

  def log_directory
    log_directory = File.join(review_lab_directory, 'logs').freeze
    return log_directory if File.exist?(log_directory)
    Dir.mkdir(log_directory)
    log_directory
  end

  def create_working_directory
    return if File.exist?(working_directory)
    msg = "Working directory #{working_directory} does not exist, creating it."
    logger.info(msg)
    Dir.mkdir(working_directory)
  end

  def all_apps
    Dir.chdir(working_directory) do
      Dir.glob('*').select { |f| File.directory?(f) && !f.include?('logs') }
    end
  end

  def orphaned_apps
    (all_apps - running_apps)
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

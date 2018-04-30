# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'active_model'
require_relative 'simple_review_app/review_app'
require_relative 'simple_review_app/pull_request_collection'
require_relative 'simple_review_app/logger'

# rubocop:disable Metrics/ClassLength
class SimpleReviewApp
  include ActiveModel::Model
  include Logger
  attr_accessor :running_apps,
                :github_username,
                :github_password,
                :github_organization,
                :github_repository,
                :github_labels,
                :host,
                :docker_compose_file_name,
                :prepare_block,
                :overlay_files_directory,
                :disable_comments
  attr_writer :logger, :data_directory

  def self.run
    main_instance.run
  end

  def self.setup
    yield main_instance
  end

  def preparation(&block)
    self.prepare_block = block
  end

  def run
    logger.info('Starting review lab.')
    self.running_apps = []
    create_data_directory
    deploy_review_apps
    destroy_review_apps
  rescue StandardError => e
    logger.error(e)
  end

  private

  class << self
    private

    def main_instance
      @main_instance ||= SimpleReviewApp.new
    end
  end

  def deploy_review_apps
    pull_requests.each do |pull_request|
      deploy_review_app(pull_request)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def deploy_review_app(pull_request)
    running_apps << ReviewApp.new(
      pull_request: pull_request,
      project_name: github_repository,
      host: host,
      client: client,
      data_directory: data_directory,
      prepare_block: prepare_block,
      overlay_files_directory: overlay_files_directory,
      docker_compose_file_name: docker_compose_file_name,
      disable_comments: disable_comments,
      logger: logger
    ).deploy
    # rubocop:enable Metrics/MethodLength
  end

  def destroy_review_apps
    orphaned_apps.each do |dir|
      ReviewApp.new(
        name: dir,
        project_name: github_repository,
        data_directory: data_directory,
        docker_compose_file_name: docker_compose_file_name,
        logger: logger
      ).destroy
    end
  end

  def data_directory
    @data_directory ||= File.join('/tmp', 'simple_review_app', 'data').freeze
  end

  def create_data_directory
    return if File.exist?(data_directory)
    msg = "Data directory #{data_directory} does not exist, creating it."
    logger.info(msg)
    FileUtils.mkdir_p(data_directory)
  end

  def all_apps
    Dir.chdir(data_directory) do
      Dir.glob('*').select { |f| File.directory?(f) }
    end
  end

  def orphaned_apps
    (all_apps - running_apps)
  end

  def pull_requests
    result = PullRequestCollection.new(
      organization: github_organization,
      repository: github_repository,
      labels: github_labels,
      client: client,
      logger: logger
    ).all
    logger.info("Found #{result.count} open pull requests.")
    result
  end

  def credentials?
    github_username.present? && github_password.present?
  end

  def client
    return @client if @client.present?
    if credentials?
      logger.info "Authenticating to GitHub with username #{github_username}."
      @client = Octokit::Client.new(login: github_username, password: github_password)
    else
      logger.info 'Using github API as anonymous user.'
      @client = Octokit::Client.new
    end
  end
end
# rubocop:enable Metrics/ClassLength

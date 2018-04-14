# frozen_string_literal: true

require 'active_model'

class ReviewAppManager
  include ActiveModel::Model
  attr_accessor :working_directory, :config
  attr_writer :logger

  def update(pull_requests)
    self.running_apps = []
    deploy_review_apps(pull_requests)
    destroy_review_apps(pull_requests)
  end

  private

  attr_accessor :running_apps

  def deploy_review_apps(pull_requests)
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
      service_name: config['service_name'],
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
    options = { working_directory: working_directory }
    orphaned_apps.each do |dir|
      ReviewApp.new(
        name: dir,
        project_name: config['github_repository'],
        options: options,
        logger: logger
      ).destroy
    end
  end

  def all_apps
    Dir.chdir(working_directory) do
      Dir.glob('*').select { |f| File.directory?(f) && !f.include?('logs') }
    end
  end

  def orphaned_apps
    (all_apps - running_apps)
  end
end

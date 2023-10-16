# frozen_string_literal: true

require 'zaru'
require 'active_model'
require 'open3'
require 'fileutils'
require_relative 'logger'
require_relative 'docker_compose_file'
require_relative 'utils'
require_relative 'pull_request_comment'

# rubocop:disable Metrics/ClassLength
class SimpleReviewApp
  class ReviewApp
    include ActiveModel::Model
    extend ActiveModel::Callbacks
    include Logger
    include Utils
    attr_accessor :pull_request,
                  :project_name,
                  :client,
                  :data_directory,
                  :prepare_block,
                  :overlay_files_directory,
                  :disable_comments
    attr_writer :name, :logger, :host, :docker_compose_file_name

    define_model_callbacks :deploy
    after_deploy PullRequestComment, unless: :disable_comments?

    def deploy
      if exists?
        update
        return name
      end

      run_callbacks :deploy do
        create
        name
      end
    end

    def destroy
      logger.info "Destroy review app '#{name}'."
      stop_app(true)
      FileUtils.rm_rf(directory)
      logger.info "Successfully destroyed app '#{name}'."
    end

    def url
      "http://#{host}/#{name}"
    end

    private

    def disable_comments?
      disable_comments || !client.login
    end

    def host
      @host ||= 'localhost'
    end

    def docker_compose_file_name
      @docker_compose_file_name ||= 'docker-compose.yml'
    end

    def update
      if pull_request.changed?(directory)
        logger.info('Pull request changed, updating...')
        pull_request.fetch_and_reset(directory)
        stop_app
      else
        logger.info('Pull request did not change, continue...')
      end
      provision
      start_app
    end

    def create
      pull_request.clone(directory)
      provision
      start_app
    end

    def provision
      execute_prepare_block
      copy_files
      docker_compose_file.update
    end

    def exists?
      return false unless ::File.exist?(directory)

      logger.info('Pull request already exists.')
      true
    end

    def start_app
      logger.info "Starting review app '#{name}'."
      do_in_project_directory do
        capture2e_with_logs("docker-compose -f #{docker_compose_file_name} pull")
        capture2e_with_logs("docker-compose -f #{docker_compose_file_name} -p #{name} up --build -d")
      end
      logger.info "Successfully started review app '#{name}'."
    end

    def stop_app(destroy = false)
      logger.info "Stopping review app '#{name}'."
      do_in_project_directory do
        if destroy
          capture2e_with_logs("docker-compose -f #{docker_compose_file_name} -p #{name} down -v")
        else
          capture2e_with_logs("docker-compose -f #{docker_compose_file_name} -p #{name} stop")
        end
      end
      logger.info "Successfully stopped review app '#{name}'."
    end

    def copy_files
      return if overlay_files_directory.blank?

      logger.info "Copy overlay files from '#{overlay_files_directory}' to '#{project_directory}'."
      FileUtils.cp_r(Dir["#{overlay_files_directory}/*"], project_directory)
    end

    def execute_prepare_block
      return if prepare_block.blank?

      do_in_project_directory do
        logger.info prepare_block.call
      end
    end

    def docker_compose_file
      @docker_compose_file ||= DockerComposeFile.new(
        path: File.join(project_directory, docker_compose_file_name),
        app_name: name,
        host:,
        logger:
      )
    end

    def name
      @name ||= Zaru.sanitize!("#{pull_request.user_login}-#{pull_request.branch}").downcase
    end

    def directory
      File.join(data_directory, name)
    end

    def project_directory
      File.join(directory, project_name)
    end

    def do_in_project_directory(&)
      Dir.chdir(project_directory, &)
    end
  end
end
# rubocop:enable Metrics/ClassLength

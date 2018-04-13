# frozen_string_literal: true

require 'zaru'
require 'active_model'
require 'open3'
require './lib/review_lab/logger'
require './lib/review_lab/docker_compose_file'
require './lib/review_lab/utils'
require './lib/review_lab/pull_request_comment'

class ReviewLab
  class ReviewApp
    include ActiveModel::Model
    extend ActiveModel::Callbacks
    include Logger
    include Utils
    attr_accessor :pull_request, :host, :project_name, :client, :service_name, :options
    attr_writer :name, :logger

    define_model_callbacks :deploy
    after_deploy PullRequestComment

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
      do_in_project_directory do
        capture2e_with_logs("docker-compose -p #{name} stop")
      end
      FileUtils.rm_rf(directory)
      logger.info "Successfully destroyed app '#{name}'."
    end

    def url
      "http://#{host}/#{name}"
    end

    private

    def update
      pull_request.update(directory)
      provision
    end

    def create
      pull_request.clone(directory)
      provision
      start_app
    end

    def provision
      execute_before_script
      copy_files
      docker_compose_file.set_review_app_information
    end

    def exists?
      File.exist?(directory)
    end

    def start_app
      logger.info "Starting review app '#{name}'."
      do_in_project_directory do
        capture2e_with_logs("docker-compose -p #{name} up -d")
      end
      logger.info "Successfully started review app '#{name}'."
    end

    def copy_files
      logger.info "Copy overlay files from '#{files_directory}' to '#{project_directory}'."
      FileUtils.cp_r(Dir[files_directory], project_directory)
    end

    def files_directory
      File.join(options[:working_directory], '..', 'files/*')
    end

    def execute_before_script
      do_in_project_directory do
        before_scripts.each do |script|
          capture2e_with_logs(script)
        end
      end
    end

    def before_scripts
      options[:before_script] || []
    end

    def docker_compose_file
      @docker_compose_file ||= DockerComposeFile.new(
        path: docker_compose_file_path,
        service_name: service_name,
        app_name: name,
        host: host,
        logger: logger
      )
    end

    def docker_compose_file_path
      "#{project_directory}/docker-compose.yml"
    end

    def name
      @name ||= Zaru.sanitize!("#{pull_request.user_login}-#{pull_request.branch}").downcase
    end

    def directory
      File.join(options[:working_directory], name)
    end

    def project_directory
      File.join(directory, project_name)
    end

    def do_in_project_directory
      Dir.chdir(project_directory) do
        yield
      end
    end
  end
end

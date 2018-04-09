# frozen_string_literal: true

require 'yaml'
require 'active_model'
require './lib/review_lab/logger'

class DockerComposeFile
  include ActiveModel::Model
  include Logger
  attr_accessor :path, :service_name
  attr_writer :content

  def content
    @content ||= YAML.load_file(docker_compose_file_path)
  end

  def save
    File.open(path, 'w') do |f|
      f.write(YAML.dump(content))
    end
  end

  def set_review_app_information
    add_traefik_frontend_rule(compose_file)
    add_relative_url_root(compose_file)
    save
  end

  private

  def service
    content['services'][service_name]
  end

  def add_relative_url_root
    logger.info "Set '#{root_url}' in docker-compose.yml file."
    service['environment'] ||= []
    service['environment'] << root_url
    content
  end

  def root_url
    "RAILS_RELATIVE_URL_ROOT=/#{name}"
  end

  def add_traefik_frontend_rule
    logger.info "Set '#{traefik_frontend_rule}' in docker-compose.yml file."
    service['labels']['traefik.frontend.rule'] = traefik_frontend_rule
    content
  end

  def traefik_frontend_rule
    "Host:#{host}; PathPrefix:/#{name}"
  end
end

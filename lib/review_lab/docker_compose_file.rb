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
  
  def add_relative_url_root(compose_file)
    logger.info "Set 'RAILS_RELATIVE_URL_ROOT=/#{name}' in docker-compose.yml file."
    content['services'][service_name]['environment'] ||= []
    content['services'][service_name]['environment'] << "RAILS_RELATIVE_URL_ROOT=/#{name}"
    content
  end
  
  def add_traefik_frontend_rule(compose_file)
    logger.info "Set 'Host:#{host}; PathPrefix:/#{name}' in docker-compose.yml file."
    content['services'][service_name]['labels']['traefik.frontend.rule'] = "Host:#{host}; PathPrefix:/#{name}"
    content
  end
end

# frozen_string_literal: true

require 'yaml'
require 'active_model'
require 'liquid'
require_relative 'logger'

class SimpleReviewApp
  class DockerComposeFile
    include ActiveModel::Model
    include Logger
    attr_accessor :path, :app_name, :host
    attr_writer :content, :logger

    def content
      @content ||= File.read(path)
    end

    def update
      result = template.render(attributes)
      File.open(path, 'w') do |f|
        f.write(result)
      end
    end

    private

    def attributes
      {
        'root_url' => root_url,
        'traefik_frontend_rule' => traefik_frontend_rule
      }
    end

    def template
      @template ||= Liquid::Template.parse(content)
    end

    def root_url
      "/#{app_name}"
    end

    def traefik_frontend_rule
      "Host:#{host}; PathPrefix:/#{app_name}"
    end
  end
end

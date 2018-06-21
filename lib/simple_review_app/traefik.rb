# frozen_string_literal: true

require 'open3'
require_relative 'utils'
require_relative 'logger'

class SimpleReviewApp
  class Traefik
    extend Utils
    extend Logger

    def self.up
      logger.info('Starting Traefik container...')
      Dir.chdir(File.join(File.dirname(__FILE__), '../traefik')) do
        capture2e_with_logs('docker-compose up -d')
      end
    end
  end
end

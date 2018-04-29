# frozen_string_literal: true

require 'logger'

class SimpleReviewApp
  module Logger
    def logger
      @logger ||= ::Logger.new(STDOUT).tap do |log|
        log.level = ::Logger::INFO
      end
    end
  end
end

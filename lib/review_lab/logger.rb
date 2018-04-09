require 'logger'

class ReviewLab
  module Logger
    def logger
      @logger ||= ::Logger.new(STDOUT).tap do |log|
        log.level = ::Logger::INFO
      end
    end
  end
end

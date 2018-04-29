# frozen_string_literal: true

class SimpleReviewApp
  module Utils
    def capture2e_with_logs(cmd)
      logger.info("Execute command '#{cmd}'.")
      stdout_and_stderr_str, status = Open3.capture2e(cmd)
      stdout_and_stderr_str.chomp!
      if status.success?
        logger.info(stdout_and_stderr_str)
      else
        logger.error(stdout_and_stderr_str)
      end
      stdout_and_stderr_str
    end
  end
end

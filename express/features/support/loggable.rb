module RHCHelper
  module Loggable
    PASSWORD_REGEX = /(.* rhc .*) -p [^\s]* /

    def logger
      Loggable.logger
    end

    def perf_logger
      Loggable.perf_logger
    end

    def self.logger
      @logger ||= Logger.STDOUT
    end

    def self.logger=(logger)
      @logger = logger
      original_formatter = Logger::Formatter.new
      @logger.formatter = proc { |severity, datetime, progname, msg|
        # Filter out any passwords
        filter_msg = msg.gsub(PASSWORD_REGEX, "#{$1} -p ***** ") 

        # Format with the original formatter
        original_formatter.call(severity, datetime, progname, filter_msg)
      }
    end

    def self.perf_logger
      @perf_logger ||= Logger.STDOUT
    end

    def self.perf_logger=(logger)
      @perf_logger = logger
    end
  end
end

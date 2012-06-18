module RHCHelper
  module Loggable
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
    end

    def self.perf_logger
      @perf_logger ||= Logger.STDOUT
    end

    def self.perf_logger=(logger)
      @perf_logger = logger
    end
  end
end

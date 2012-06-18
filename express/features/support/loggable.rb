module RHCHelper
  module Loggable
    attr_accessor :logger, :perf_logger

    def logger
      Loggable.logger
    end

    def perf_logger
      Loggable.perf_logger
    end

    def self.logger
      @logger ||= Logger.STDOUT
    end

    def self.perf_logger
      @perf_logger ||= Logger.STDOUT
    end
  end
end

$: << File.expand_path(File.dirname(__FILE__))

require 'tmpdir'
require 'rhc/app_helper'

#
# Define global variables
#
$temp = File.join(Dir.tmpdir, "rhc")
$domain = "rhcloud.com"

AfterConfiguration do |config|
  # Create the temporary space
  FileUtils.mkdir_p $temp

  # Setup the logger
  logger = Logger.new(File.join($temp, "cucumber.log"))
  logger.level = Logger::DEBUG
  RHCHelper::Loggable.logger = logger

  # Setup performance monitor logger
  perf_logger = Logger.new(File.join($temp, "perfmon.log"))
  perf_logger.level = Logger::INFO
  RHCHelper::Loggable.perf_logger = perf_logger

  # Use a username and password from the environment if they exist
  $login = ENV['RHC_RHLOGIN']
  $password = ENV['RHC_PWD']
  $namespace = ENV['RHC_NAMESPACE']
end

World(RHCHelper)

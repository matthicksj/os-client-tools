require 'fileutils'
require 'logger'

#
# Define global variables
#
$temp = "/tmp/rhc"

$client_config = "/etc/openshift/express.conf"
 
# Use the domain from the rails application configuration
$domain = "example.com"

# Alternate domain suffix for use in alias commands
$alias_domain = "foobar.com"

# RSA Key constants
$test_pub_key = File.expand_path("~/.ssh/libra_id_rsa.pub")
$test_priv_key = File.expand_path("~/.ssh/libra_id_rsa")

module SetupHelper
  def self.setup
    # Create the temporary space
    FileUtils.mkdir_p $temp

    # Setup the logger
    $logger = Logger.new(File.join($temp, "cucumber.log"))
    $logger.level = Logger::DEBUG
    $logger.formatter = proc do |severity, datetime, progname, msg|
        "#{$$} #{severity} #{datetime}: #{msg}\n"
    end

    # Setup performance monitor logger
    $perfmon_logger = Logger.new(File.join($temp, "perfmon.log"))
    $perfmon_logger.level = Logger::INFO
    $perfmon_logger.formatter = proc do |severity, datetime, progname, msg|
        "#{$$} #{datetime}: #{msg}\n"
    end

    # If the default ssh key is not present, create one
    `ssh-keygen -q -f #{$test_priv_key} -P ''` if !File.exists?($test_priv_key)
    FileUtils.chmod 0600, $test_priv_key
  end
end
World(SetupHelper)

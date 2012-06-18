require 'active_support'
require 'dnsruby'
require 'pp'

module RHCHelper
  class App
    include ActiveSupport::JSON
    include Dnsruby
    include Commandify
    include Runnable
    include Persistable

    attr_accessor :logger, :perf_logger

    # attributes to represent the general information of the application
    attr_accessor :name, :namespace, :login, :password, :type, :hostname, :repo, :embed, :snapshot, :uid, :alias

    # attributes that contain statistics based on calls to connect
    attr_accessor :response_code, :response_time

    # mysql connection information
    attr_accessor :mysql_hostname, :mysql_user, :mysql_password, :mysql_database

    def logger
      @logger = $logger ? $logger : Logger.new(STDOUT)
    end

    def perf_logger
      @perf_logger = $perf_logger ? $perf_logger : Logger.new(STDOUT)
    end

    # Create the data structure for a test application
    def initialize(namespace, login, type, name, password)
      @name, @namespace, @login, @type, @password = name, namespace, login, type, password
      @hostname = "#{name}-#{namespace}.#{$domain}"
      @repo = "#{$temp}/#{namespace}_#{name}_repo"
      @file = "#{$temp}/#{namespace}.json"
      @embed = []
    end

    def self.create_unique(type, name="test")
      loop do
        # Generate a random username
        chars = ("1".."9").to_a
        namespace = $namespace ? $namespace : "rhc" + Array.new(8, '').collect{chars[rand(chars.size)]}.join
        login = $login ? $login : "rhc-test_#{namespace}@example.com"
        password = $password ? $password : "supersecret"
        app = App.new(namespace, login, type, name, password)
        if $namespace || !app.reserved?
          app.persist
          return app
        end
      end
    end

    def reserved?
      # If we get a response, then the namespace is reserved
      # An exception means that it is available
      begin
        Dnsruby::Resolver.new.query("#{@namespace}.#{$domain}", Dnsruby::Types::TXT)
        return true
      rescue Dnsruby::NXDomain
        return false
      end
    end

    def get_index_file
      case @type
        when "php-5.3" then "php/index.php"
        when "ruby-1.8" then "config.ru"
        when "python-2.6" then "wsgi/application"
        when "perl-5.10" then "perl/index.pl"
        when "jbossas-7" then "src/main/webapp/index.html"
        when "jbosseap-6.0" then "src/main/webapp/index.html"
        when "nodejs-0.6" then "index.html"
      end
    end

    def get_mysql_file
      case @type
        when "php-5.3" then File.expand_path("../misc/php/db_test.php", File.expand_path(File.dirname(__FILE__)))
      end
    end

    def curl(url, timeout=30)
      # TODO - replace with Net::HTTP
      body = `curl --insecure -s --max-time #{timeout} #{url}`
      exit_code = $?.exitstatus

      return exit_code, body
    end

    def curl_head_success?(url, host=nil, http_code=200)
      response_code = curl_head(url, host)
      is_http = url.start_with?('http://')
      if (is_http && response_code.to_i == 301)
        url = "https://#{url[7..-1]}"
        response_code = curl_head(url, host)
      end
      return response_code.to_i == http_code 
    end
    
    def curl_head(url, host=nil)
      # TODO - replace with Net::HTTP
      response_code = nil
      if host
        response_code = `curl -w %{http_code} --output /dev/null --insecure -s --head -H 'Host: #{host}' --max-time 30 #{url}`
      else
        response_code = `curl -w %{http_code} --output /dev/null --insecure -s --head --max-time 30 #{url}`
      end
      response_code 
    end

    def is_inaccessible?(max_retries=60)
      max_retries.times do |i|
        if !curl_head_success?("http://#{hostname}")
          return true
        else
          $logger.info("Connection still accessible / retry #{i} / #{hostname}")
          sleep 1
        end
      end
      return false
    end

    # Host is for the host header
    def is_accessible?(use_https=false, max_retries=120, host=nil)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      max_retries.times do |i|
        if curl_head_success?(url, host)
          return true
        else
          $logger.info("Connection still inaccessible / retry #{i} / #{url}")
          sleep 1
        end
      end

      return false
    end

    def is_temporarily_unavailable?(use_https=false, host=nil)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      if curl_head_success?(url, host, 503)
        return true
      else
        return false
      end
    end

    def connect(use_https=false, max_retries=30)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      $logger.info("Connecting to #{url}")
      beginning_time = Time.now

      max_retries.times do |i|
        code, body = curl(url, 1)

        if code == 0
          @response_code = code.to_i
          @response_time = Time.now - beginning_time
          $logger.info("Connection result = #{code} / #{url}")
          $logger.info("Connection response time = #{@response_time} / #{url}")
          return body
        else
          $logger.info("Connection failed / retry #{i} / #{url}")
          sleep 1
        end
      end

      return nil
    end
  end
end

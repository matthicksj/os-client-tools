require 'dnsruby'
require 'rhc/loggable'
require 'rhc/commandify'
require 'rhc/runnable'
require 'rhc/persistable'
require 'rhc/httpify'

module RHCHelper
  class App 
    extend Persistable
    include Dnsruby
    include Loggable
    include Commandify
    include Runnable
    include Persistify
    include Httpify

    # attributes to represent the general information of the application
    attr_accessor :name, :namespace, :login, :password, :type, :hostname, :repo, :embed, :snapshot, :uid, :alias

    # mysql connection information
    attr_accessor :mysql_hostname, :mysql_user, :mysql_password, :mysql_database

    # Create the data structure for a test application
    def initialize(namespace, login, type, name, password=nil)
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
  end
end

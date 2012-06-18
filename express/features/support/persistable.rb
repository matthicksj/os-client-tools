require 'active_support'

module RHCHelper
  module Persistable
    include ActiveSupport::JSON
    include Loggable

    # a file to represent the local storage
    attr_accessor :file

    def self.find_on_fs
      Dir.glob("#{$temp}/*.json").collect {|f| App.from_file(f)}
    end

    def self.from_file(filename)
      App.from_json(ActiveSupport::JSON.decode(File.open(filename, "r") {|f| f.readlines}[0]))
    end

    def self.from_json(json)
      app = App.new(json['namespace'], json['login'], json['type'], json['name'])
      app.embed = json['embed']
      app.mysql_user = json['mysql_user']
      app.mysql_password = json['mysql_password']
      app.mysql_hostname = json['mysql_hostname']
      app.uid = json['uid']
      return app
    end

    def persist
      json = self.as_json(:except => [:logger, :perf_logger])
      File.open(@file, "w") {|f| f.puts json}
    end
  end
end

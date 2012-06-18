require 'uri'

module RHCHelper
  module Httpify
    include Loggable

    # attributes that contain statistics based on calls to connect
    attr_accessor :response_code, :response_time

    def http_instance(url, timeout=30)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host)
      http.open_timeout = timeout
      http.connect_timeout = timeout
      if (uri.scheme == "https")
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      return http
    end

    def http_get(url, timeout=30)
      http = http_instance(url, timeout)
      http.start
      request = Net::HTTP::Get.new(uri.request_uri)
      http.request(request)
    end
    
    def http_head(url, host=nil, follow_redirects=true)
      http = http_instance(url)
      http.start
      request = Net::HTTP::Head.new(uri.request_uri)
      request["Host"] = host if host
      response = http.request(request)
      
      if follow_redirects and response.is_a?(Net::HTTPRedirection)
        return http_head(response.header['location'])
      else
        return response
      end
    end

    def is_inaccessible?(max_retries=60)
      max_retries.times do |i|
        if http_head("http://#{hostname}").is_a? Net::HTTPServerError
          return true
        else
          logger.info("Connection still accessible / retry #{i} / #{hostname}")
          sleep 1
        end
      end
      return false
    end

    def is_accessible?(use_https=false, max_retries=120, host=nil)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      max_retries.times do |i|
        if http_head(url, host).is_a? Net::HTTPSuccess
          return true
        else
          logger.info("Connection still inaccessible / retry #{i} / #{url}")
          sleep 1
        end
      end

      return false
    end

    def is_temporarily_unavailable?(use_https=false, host=nil)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      if http_head(url, host).is_a? Net::HTTPServiceUnavailable 
        return true
      else
        return false
      end
    end

    def connect(use_https=false, max_retries=30)
      prefix = use_https ? "https://" : "http://"
      url = prefix + hostname

      logger.info("Connecting to #{url}")
      beginning_time = Time.now

      max_retries.times do |i|
        response = http_get(url, 1)

        if response.is_a? Net::HTTPSuccess
          @response_code = response.code
          @response_time = Time.now - beginning_time
          logger.info("Connection result = #{@response_code} / #{url}")
          logger.info("Connection response time = #{@response_time} / #{url}")
          return response.body
        else
          logger.info("Connection failed / retry #{i} / #{url}")
          sleep 1
        end
      end

      return nil
    end
  end
end

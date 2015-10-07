#Encoding: UTF-8
require "httparty"
require "active_support/core_ext/string"

module Middleman
  module Cli
	  class AkamaiClient
	    def initialize(username, password)
	      @auth = {:username => username, :password => password}
	    end

	    def invalidate(urls)
		    path = "/ccu/v2/queues/default"
        response = api_post(path, {
          :objects => urls
        })
        case response.header.code
	    	when "201"
	        # success
	      when "400"
	        error_message = response.headers["x-purge-failed-reason"]
	        raise "400, #{error_message}" if error_message.present?
	        raise "400, an error occurred."
	      when "403"
	        raise "403, check the authorizations for the client and the objects being purged."
	      when "415"
	        raise "415, bad media type. Typically a missing header."
	      when "507"
	        raise "507, over queue limit. Wait at least a few minutes to try again."
	      else
	        error_message = response.body
	        raise "#{response.header.code}, an error occurred. #{error_message}".rstrip
	      end
	    end
		  private

			def api_post(path, content)
				self.class.post(path, {
		    	:headers => {'Accept' => 'application/json', 'Content-Type' => 'application/json'},
		    	:basic_auth => @auth,
		    	:body => content.to_json
		    })
			end

			def api_get(path, content)
		    self.class.get(path, {
	        :headers => {'Accept' => 'application/json', 'Content-Type' => 'application/json'},
	        :basic_auth => @auth,
	        :query => content
		    })
			end
	  end
	end
end
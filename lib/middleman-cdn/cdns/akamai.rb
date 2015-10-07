#Encoding: UTF-8
require "httparty"
require "active_support/core_ext/string"
require "middleman-cdn/clients/akamai.rb"

module Middleman
  module Cli
    class AkamaiCDN < BaseCDN

      def self.key
        "akamai"
      end

      def self.example_configuration_elements
        {
          username: ['"..."', "# default ENV['AKAMAI_USERNAME']"],
          password: ['"..."', "# default ENV['AKAMAI_PASSWORD']"],
          base_url: ['"..."', "# default ENV['AKAMAI_BASE_URL']"]
        }
      end

      def invalidate(options, files, all: false)
        options[:username] ||= ENV['AKAMAI_USERNAME']
        options[:password] ||= ENV['AKAMAI_PASSWORD']
        options[:base_url] ||= ENV['AKAMAI_BASE_URL']

        [:username, :password, :base_url].each do |key|
          if options[key].blank?
            say_status(ANSI.red{ "Error: Configuration key akamai[:#{key}] is missing." })
            raise
          end
        end

        akamai_client = AkamaiClient.new(options[:username], options[:password])

        begin
          files = [files] if files.is_a?(String)
          urls = files.map { |file| "#{options[:base_url]}#{file}" }
          akamai_client.invalidate(urls)
        rescue => e
          say_status(", " + ANSI.red{ "error: #{e.message}" }, header: false)
        else
          say_status(ANSI.green{ "✔" }, header: false)
        end
      end
    end
  end
end

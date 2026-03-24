# frozen_string_literal: true
require "faraday"
require_relative "open_alex_wrap/version"
require_relative "open_alex_wrap/client/authors"
require_relative 'open_alex_wrap/client/base'
require_relative 'open_alex_wrap/client/works'
require_relative 'open_alex_wrap/client/topics'
require_relative 'open_alex_wrap/client/pagination'
require_relative 'open_alex_wrap/client/sources'

module OpenAlexWrap
  include Base
  include Works
  include Authors
  include Sources
  include Topics
  include Pagination
  class Error < StandardError; end
  class Client
    BASE_URL = "https://api.openalex.org"

    def initialize(email:, api_key: nil, timeout: 10)
      @email = email
      @api_key = api_key
      @timeout = timeout
      @connection = set_connection
    end


    private
    def set_connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.headers["mailto"] = @email
        conn.headers["apikey"] = @api_key if @api_key
        conn.headers["User-Agent"] = "OpenAlexWrap/#{VERSION} (mailto:#{@email})"

        conn.options.timeout = @timeout
        conn.options.open_timeout = @timeout

      end
    end
    def parse_response(response)
      return response.body if response.success?

      # Обработка ошибок
      error_message = response.body["message"] || "Unknown error"
      raise Error, "OpenAlex API error (#{response.status}): #{error_message}"
    end
  end
end

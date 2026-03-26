# frozen_string_literal: true
require "faraday"
require "json"
require_relative "open_alex_wrap/version"
require_relative "open_alex_wrap/client/authors"
require_relative 'open_alex_wrap/client/base'
require_relative 'open_alex_wrap/client/works'
require_relative 'open_alex_wrap/client/topics'
require_relative 'open_alex_wrap/client/pagination'
require_relative 'open_alex_wrap/client/sources'

module OpenAlexWrap

  class Error < StandardError;
  end
  class Client
    include Base
    include Works
    include Authors
    include Sources
    include Topics
    include Pagination

    BASE_URL = "https://api.openalex.org"

    def initialize(email:, api_key: nil, timeout: 10)
      @email = email
      @api_key = api_key
      @timeout = timeout
      @connection = set_connection
    end


  end
end

# frozen_string_literal: true

# TODO: Базовые методы для запросов к openalex

module OpenAlexWrap
  module Base
    BASE_URL = "https://api.openalex.org"
    private
    def set_connection
      Faraday.new(url: BASE_URL) do |conn|
        conn.headers["mailto"] = @email
        conn.headers["apikey"] = @api_key if @api_key
        conn.headers["User-Agent"] = "OpenAlexWrap/#{VERSION} (mailto:#{@email})"

        conn.options.timeout = @timeout
        conn.options.open_timeout = @timeout

        conn.response :json

      end
    end

  end
  end
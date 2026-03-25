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

    def format_filter(filter)
      case filter
      when Hash
        # Пример: { publication_year: 2024, open_access: true }
        # Результат: "publication_year:2024,open_access:true"
        filter.map { |k, v| "#{k}:#{v}" }.join(",")
      when String
        filter
      else
        filter.to_s
      end
    end

    def format_sort(sort)
      case sort
      when Hash
        # Пример: { cited_by_count: :desc, publication_date: :asc }
        # Результат: "cited_by_count:desc,publication_date:asc"
        sort.map { |k, v| "#{k}:#{v}" }.join(",")
      when String
        sort
      else
        sort.to_s
      end
    end
    def query(type, filter: nil, sort: nil, group_by: nil, search: nil, sample: nil, select: nil, page: nil, per_page: nil, cursor: nil)
      params = {}
      params[:filter] = format_filter(filter) if filter
      params[:sort] = format_sort(sort) if sort
      params[:group_by] = group_by if group_by
      params[:search] = search if search
      params[:select] = select if select
      params[:sample] = sample if sample
      params[:page] = page if page
      params[:per_page] = per_page if per_page
      params[:cursor] = cursor if cursor

      case type.to_s
      when "work"
        response = @connection.get("works", params)
      when "author"
        response = @connection.get("authors", params)
      when "source"
        response = @connection.get("sources", params)
      when "topic"
        response = @connection.get("topics", params)
      else
        raise ArgumentError, "Unknown type: #{type}. Available: work, author, source, topic"
      end
      parse_response(response)
    end

    private
    def parse_response(response)
      return response.body if response.success?

      # Обработка ошибок
      error_message = response.body["message"] || "Unknown error"
      raise Error, "OpenAlex API error (#{response.status}): #{error_message}"
    end
  end
end

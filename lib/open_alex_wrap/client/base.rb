# frozen_string_literal: true

# TODO: Базовые методы для запросов к openalex

module OpenAlexWrap
  module Base
    BASE_URL = "https://api.openalex.org"

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

    def format_select(select)
      case select
      when Array
        # Для массива: ["id", "title", "doi"] => "id,title,doi"
        select.map(&:to_s).join(",")
      when Hash
        # Для хэша: { work: [:id, :title], author: [:name] } => "work.id,work.title,author.name"
        select.map do |key, fields|
          Array(fields).map { |field| "#{key}.#{field}" }.join(",")
        end.join(",")
      when String
        # Если уже строка - возвращаем как есть
        select
      when nil
        nil
      else
        select.to_s
      end
    end

    def query(type, filter: nil, sort: nil, group_by: nil, search: nil, sample: nil, select: nil, page: nil, per_page: 25, cursor: "*")
      params = {}
      params[:filter] = format_filter(filter) if filter
      params[:sort] = format_sort(sort) if sort
      params[:group_by] = group_by if group_by
      params[:search] = search if search
      params[:select] = format_select(select) if select
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
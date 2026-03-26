# frozen_string_literal: true

# TODO: Методы поиска по источникам

module OpenAlexWrap
  module Sources
    require Base
    # Получить источники с наибольшим количеством цитирований
    # @param limit [Integer] количество источников
    # @return [Hash] ответ от API
    def most_cited_sources(limit: 100)
      query(:source,
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "display_name,cited_by_count,works_count,issn,host_organization"
      )
    end

    # Поиск источников по названию
    # @param name [String] название для поиска
    # @param limit [Integer] количество результатов
    # @return [Hash] ответ от API
    def search_sources(name, limit: 20)
      query(:source,
            search: name,
            per_page: limit,
            select: "display_name,works_count,cited_by_count,issn"
      )
    end

    # Получить источники с открытым доступом
    # @param limit [Integer] количество источников
    # @return [Hash] ответ от API
    def open_access_sources(limit: 50)
      query(:source,
            filter: { is_in_doaj: true },
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "display_name,cited_by_count,works_count,issn"
      )
    end

    # Получить источники по ID издателя
    # @param publisher_id [String] ID издателя (например, "https://openalex.org/P4310320068")
    # @param limit [Integer] количество результатов
    # @return [Hash] ответ от API
    def sources_by_publisher_id(publisher_id, limit: 50)
      query(:source,
            filter: { "host_organization.id": publisher_id },
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "display_name,cited_by_count,works_count,issn,host_organization"
      )
    end

    # Получить источники по стране
    # @param country_code [String] код страны (например, "US", "GB", "DE")
    # @param limit [Integer] количество источников
    # @return [Hash] ответ от API
    def sources_by_country(country_code, limit: 50)
      query(:source,
            filter: { country_code: country_code },
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "display_name,cited_by_count,works_count,issn,host_organization"
      )
    end

    # Получить источник по ISSN
    # @param issn [String] ISSN (например, "1476-4687")
    # @return [Hash] ответ от API
    def source_by_issn(issn)
      query(:source,
            filter: { issn: issn },
            per_page: 1,
            select: "display_name,cited_by_count,works_count,issn,host_organization"
      )
    end

    # Получить источники с наибольшим количеством работ
    # @param limit [Integer] количество источников
    # @return [Hash] ответ от API
    def most_prolific_sources(limit: 100)
      query(:source,
            sort: { works_count: :desc },
            per_page: limit,
            select: "display_name,works_count,cited_by_count,issn"
      )
    end
  end
end
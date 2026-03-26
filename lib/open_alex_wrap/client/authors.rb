# frozen_string_literal: true

# TODO: Методы для поиска по авторам
require_relative "base"

module OpenAlexWrap
  module Authors
    include Base
    # Получить авторов с наибольшим числом цитирований
    # @param limit [Integer] количество авторов (по умолчанию 100)
    # @param per_page [Integer] количество на странице (макс 200)
    # @return [Hash] ответ от API
    def most_cited_authors(limit: 100, per_page: 200)
      query(:author,
            sort: { cited_by_count: :desc },
            per_page: [limit, per_page].min,
            select: "display_name,cited_by_count,works_count,summary_stats,ids,last_known_institutions"
      )
    end

      # Поиск авторов по имени
      # @param name [String] имя для поиска
      # @param limit [Integer] количество результатов
      # @return [Hash] ответ от API
    def search_authors(name, limit: 20)
      query(:author,
            search: name,
            per_page: limit,
            select: "display_name,works_count,cited_by_count,ids,last_known_institutions"
      )
    end

      # Получить авторов из указанного института
      # @param institution_id [String] ID института (например, "i123456")
      # @param limit [Integer] количество результатов
      # @return [Hash] ответ от API
    def authors_by_institution(institution_id, limit: 50)
      query(:author,
            filter: { "affiliations.institution.id": institution_id },
            per_page: limit,
            select: "display_name,works_count,cited_by_count,ids,summary_stats"
      )
    end

    # Получить авторов с наибольшим количеством работ
    # @param limit [Integer] количество авторов
    # @return [Hash] ответ от API
    def most_prolific_authors(limit: 100)
      query(:author,
            sort: { works_count: :desc },
            per_page: limit,
            select: "display_name,works_count,cited_by_count,summary_stats,ids"
      )
    end

    # Получить автора по ORCID
    # @param orcid [String] ORCID автора (например, "0000-0000-0000-0000")
    # @return [Hash] ответ от API
    def author_by_orcid(orcid)
      query(:author,
            filter: { orcid: orcid },
            per_page: 1,
            select: "display_name,works_count,cited_by_count,summary_stats,ids,last_known_institutions"
      )
    end

    # Получить авторов с наибольшим h-index (используя summary_stats)
    # Примечание: h-index не является прямым полем, он находится в summary_stats
    # @param limit [Integer] количество авторов
    # @return [Hash] ответ от API
    def top_authors_by_hindex(limit: 100)
      # Получаем авторов с summary_stats и сортируем в Ruby
      response = query(:author,
                       per_page: limit,
                       select: "display_name,works_count,cited_by_count,summary_stats,ids"
      )

      # Сортируем по h-index из summary_stats
      if response && response["results"]
        response["results"].sort_by! do |author|
          - (author.dig("summary_stats", "h_index") || 0)
        end
      end

      response
    end
    end
    end

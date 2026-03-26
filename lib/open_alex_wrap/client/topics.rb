# frozen_string_literal: true

# TODO: Методы поиска по темам

module OpenAlexWrap
  module Topics
    # Получить информацию о теме по ID
    # @param topic_id [String] ID темы (например, "T11636")
    # @return [Hash] ответ от API
    def topic(topic_id)
      query(:topic,
            filter: { id: topic_id },
            per_page: 1
      )
    end

    # Получить наиболее популярные темы (по количеству работ)
    # @param limit [Integer] количество тем
    # @return [Hash] ответ от API
    def most_popular_topics(limit: 100)
      query(:topic,
            sort: { works_count: :desc },
            per_page: limit,
            select: "display_name,works_count,cited_by_count,keywords"
      )
    end

    # Поиск тем по названию
    # @param name [String] название для поиска
    # @param limit [Integer] количество результатов
    # @return [Hash] ответ от API
    def search_topics(name, limit: 20)
      query(:topic,
            search: name,
            per_page: limit,
            select: "display_name,works_count,cited_by_count"
      )
    end

    # Получить работы по теме
    # @param topic_id [String] ID темы
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def works_by_topic(topic_id, limit: 50)
      query(:work,
            filter: { "topics.id": topic_id },
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi,authorships"
      )
    end

    # Получить темы по домену
    # @param domain_id [String] ID домена (например, "D1" - Physical Sciences)
    # @param limit [Integer] количество тем
    # @return [Hash] ответ от API
    def topics_by_domain(domain_id, limit: 100)
      query(:topic,
            filter: { "domain.id": domain_id },
            sort: { works_count: :desc },
            per_page: limit,
            select: "display_name,works_count,cited_by_count"
      )
    end

    # Получить темы по полю (field)
    # @param field_id [String] ID поля
    # @param limit [Integer] количество тем
    # @return [Hash] ответ от API
    def topics_by_field(field_id, limit: 100)
      query(:topic,
            filter: { "field.id": field_id },
            sort: { works_count: :desc },
            per_page: limit,
            select: "display_name,works_count,cited_by_count"
      )
    end

    # Получить темы по субполю (subfield)
    # @param subfield_id [String] ID субполя
    # @param limit [Integer] количество тем
    # @return [Hash] ответ от API
    #def topics_by_subfield(subfield_id, limit: 100)
    #query(:topic,
    #filter: { "subfield.id": subfield_id },
    #sort: { works_count: :desc },
    #per_page: limit,
    #select: "display_name,works_count,cited_by_count"
    #)
    #end

    # Получить иерархию темы (предки)
    # @param topic_id [String] ID темы
    # @return [Array] массив предков
    def topic_hierarchy(topic_id)
      result = topic(topic_id)
      return [] unless result["results"]&.any?

      topic_data = result["results"].first
      hierarchy = []

      # Добавляем домен
      if topic_data["domain"]
        hierarchy << { level: "domain", name: topic_data["domain"]["display_name"], id: topic_data["domain"]["id"] }
      end

      # Добавляем поле
      if topic_data["field"]
        hierarchy << { level: "field", name: topic_data["field"]["display_name"], id: topic_data["field"]["id"] }
      end

      # Добавляем субполе
      if topic_data["subfield"]
        hierarchy << { level: "subfield", name: topic_data["subfield"]["display_name"], id: topic_data["subfield"]["id"] }
      end

      # Добавляем саму тему
      hierarchy << { level: "topic", name: topic_data["display_name"], id: topic_id }

      hierarchy
    end

    # Получить статистику по теме
    # @param topic_id [String] ID темы
    # @return [Hash] статистика
    def topic_stats(topic_id)
      result = topic(topic_id)
      return nil unless result["results"]&.any?

      topic_data = result["results"].first
      {
        name: topic_data["display_name"],
        works_count: topic_data["works_count"],
        cited_by_count: topic_data["cited_by_count"],
        keywords: topic_data["keywords"],
        domain: topic_data.dig("domain", "display_name"),
        field: topic_data.dig("field", "display_name"),
        subfield: topic_data.dig("subfield", "display_name")
      }
    end

    # Получить топ N тем по цитированиям
    # @param limit [Integer] количество тем
    # @return [Hash] ответ от API
    def top_cited_topics(limit: 100)
      query(:topic,
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "display_name,works_count,cited_by_count"
      )
    end

    # Поиск тем с пагинацией
    # @param filter [Hash] фильтры
    # @param per_page [Integer] количество на странице
    # @yield [Hash] каждая тема
    # @return [Integer] количество обработанных тем
    # ПРИМЕР: count = 0; client_Anna.each_topic { |t| count += 1 if t["works_count"].to_i > 10000 }; puts "Тем с >10000 работ: #{count}"
    def each_topic(filter: {}, per_page: 200, &block)
      return to_enum(:each_topic, filter: filter, per_page: per_page) unless block_given?

      cursor = "*"
      count = 0

      loop do
        response = query(:topic,
                         filter: filter,
                         cursor: cursor,
                         per_page: per_page,
                         select: "display_name,works_count,cited_by_count"
        )

        results = response["results"]
        break if results.nil? || results.empty?

        results.each do |topic|
          yield topic
          count += 1
        end

        cursor = response["meta"]["next_cursor"]
        break if cursor.nil? || cursor.empty?
      end

      count
    end
  end
end
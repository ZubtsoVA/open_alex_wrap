# frozen_string_literal: true

# TODO: Методы для поиска конкретных работ (works)
require_relative "base"
module OpenAlexWrap
  module Works
    include Base
    # Получить работу по ID (используя прямой эндпоинт)
    # @param id [String] ID работы (например, "W123456789")
    # @return [Hash] ответ от API
    def work(id)
      response = @connection.get("/works/#{id}")
      parse_response(response)
    end

    # Получить наиболее цитируемые работы
    # @param year [Integer] год публикации (опционально)
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def most_cited_works(year: nil, limit: 100)
      filter = {}
      filter[:publication_year] = year if year

      query(:work,
            filter: filter,
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi,authorships,open_access"
      )
    end

    # Наиболее свежие работы
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def latest_works(limit: 100)
      filter = {}
      filter[:publication_year] = "<#{Time.now.year + 1}"
      filter[:cited_by_count] = ">0"
      query(:work,
            sort: { publication_date: :desc },
            per_page: limit,
            select: "title,publication_year,publication_date,cited_by_count,doi,authorships",
            filter: filter
            )
    end

    # Поиск работ по ключевым словам
    # @param query_string [String] поисковый запрос
    # @param year [Integer] год публикации (опционально)
    # @param open_access [Boolean] только открытый доступ (опционально)
    # @param limit [Integer] количество результатов
    # @return [Hash] ответ от API
    def search_works(query_string, year: nil, open_access: nil, limit: 20)
      filter = {}
      filter[:publication_year] = year if year
      filter[:open_access] = open_access if open_access

      query(:work,
            search: query_string,
            filter: filter,
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi,authorships,open_access"
      )
    end

    # Получить работы автора
    # @param author_id [String] ID автора
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def works_by_author(author_id, limit: 50)
      query(:work,
            filter: { "author.id": author_id },
            sort: { publication_date: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi,authorships"
      )
    end

    # Получить работы из источника (журнала)
    # @param source_id [String] ID источника
    # @param year [Integer] год (опционально)
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def works_by_source(source_id, year: nil, limit: 50)
      filter = { "locations.source.id": source_id }
      filter[:publication_year] = year if year

      query(:work,
            filter: filter,
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi,authorships"
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
            select: "title,publication_year,cited_by_count,doi,authorships,concepts"
      )
    end

    # Получить работы по концепции
    # @param concept_id [String] ID концепции
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def works_by_concept(concept_id, limit: 50)
      query(:work,
            filter: { "concepts.id": concept_id },
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi,concepts"
      )
    end

    # Получить работы с открытым доступом
    # @param year [Integer] год (опционально)
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def open_access_works(year: nil, limit: 100)
      filter = { is_oa: true }
      filter[:publication_year] = year if year

      query(:work,
            filter: filter,
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi,open_access"
      )
    end

    # Получить работы за указанный год
    # @param year [Integer] год
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def works_by_year(year, limit: 100)
      query(:work,
            filter: { publication_year: year },
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi"
      )
    end

    # Получить работу по DOI
    # @param doi [String] DOI работы
    # @return [Hash] ответ от API
    def work_by_doi(doi)
      # Очищаем DOI от префикса https://doi.org/ если он есть
      clean_doi = doi.gsub("https://doi.org/", "").gsub("http://doi.org/", "")

      query(:work,
            filter: { doi: clean_doi },
            per_page: 1,
            select: "title,publication_year,cited_by_count,doi,authorships,abstract_inverted_index"
      )
    end

    # Получить работы с высоким уровнем цитирования
    # @param min_citations [Integer] минимальное количество цитирований
    # @param year [Integer] год (опционально)
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def highly_cited_works(min_citations: 100, year: nil, limit: 100)
      filter = { cited_by_count: ">#{min_citations}" }
      filter[:publication_year] = year if year

      query(:work,
            filter: filter,
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi,authorships"
      )
    end

    # Получить работы по типу
    # @param work_type [String] тип работы (article, book, dissertation и т.д.)
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def works_by_type(work_type, limit: 100)
      query(:work,
            filter: { type: work_type },
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,type,doi"
      )
    end

    # Получить работы по языку
    # @param language [String] код языка (en, ru, zh и т.д.)
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def works_by_language(language, limit: 100)
      query(:work,
            filter: { language: language },
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,language,doi"
      )
    end

    # Получить работы с пагинацией (все результаты)
    # @param filter [Hash] фильтры
    # @param per_page [Integer] количество на странице
    # @yield [Hash] каждая работа
    # @return [Integer] количество обработанных работ
    def each_work(filter: {}, per_page: 200, &block)
      return to_enum(:each_work, filter: filter, per_page: per_page) unless block_given?

      cursor = "*"
      count = 0

      loop do
        response = query(:work,
                         filter: filter,
                         cursor: cursor,
                         per_page: per_page,
                         select: "title,publication_year,cited_by_count,doi"
        )

        results = response["results"]
        break if results.nil? || results.empty?

        results.each do |work|
          yield work
          count += 1
        end

        cursor = response["meta"]["next_cursor"]
        break if cursor.nil? || cursor.empty?
      end

      count
    end

    # Получить статистику по работам
    # @param filter [Hash] фильтры
    # @return [Hash] статистика
    def works_stats(filter: {})
      response = query(:work,
                       filter: filter,
                       per_page: 1
      )

      response["meta"]
    end

    # Получить работы соавторов
    # @param author_ids [Array] массив ID авторов
    # @param limit [Integer] количество работ
    # @return [Hash] ответ от API
    def works_by_coauthors(author_ids, limit: 50)
      # Преобразуем строку в массив, если передана строка
      author_ids = Array(author_ids)

      filter = { "author.id": author_ids.join("|") }

      query(:work,
            filter: filter,
            sort: { cited_by_count: :desc },
            per_page: limit,
            select: "title,publication_year,cited_by_count,doi,authorships"
      )
    end
  end
end
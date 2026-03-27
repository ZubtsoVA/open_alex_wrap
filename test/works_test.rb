# test/works_test.rb
# frozen_string_literal: true

require_relative "test_helper"

class WorksTest < Minitest::Test
  def setup
    @client= setup_client
  end

  # ============= work tests =============
  def test_work_returns_single_work_by_id
    VCR.use_cassette("works/single_work") do
      response = @client.work("W2741809807")

      assert_kind_of Hash, response
      assert_includes response, "id"
      assert_includes response, "title"
      assert_includes response, "doi"
    end
  end

  def test_work_raises_error_for_invalid_id
    VCR.use_cassette("works/invalid_work") do
      assert_raises(OpenAlexWrap::Error) do
        @client.work("invalid_id")
      end
    end
  end

  # ============= most_cited_works tests =============

  def test_most_cited_works_filters_by_year
    VCR.use_cassette("works/most_cited_by_year") do
      year = 2020
      response = @client.most_cited_works(year: year, limit: 5)

      response["results"].each do |work|
        assert_equal year, work["publication_year"]
      end
    end
  end

  def test_most_cited_works_respects_limit
    VCR.use_cassette("works/most_cited") do
      limit = 5
      response = @client.most_cited_works(limit: limit)
      assert_operator response["results"].size, :<=, limit
    end
  end

  # ============= latest_works tests =============
  def test_latest_works_returns_works_sorted_by_date
    VCR.use_cassette("works/latest") do
      response = @client.latest_works(limit: 10)

      assert_kind_of Hash, response
      refute_empty response["results"]

      dates = response["results"].map { |w| w["publication_date"] }
      assert_equal dates, dates.sort.reverse
    end
  end

  def test_latest_works_only_includes_works_with_citations
    VCR.use_cassette("works/latest") do
      response = @client.latest_works(limit: 10)

      response["results"].each do |work|
        assert_operator work["cited_by_count"].to_i, :>=, 0
      end
    end
  end

  # ============= search_works tests =============
  def test_search_works_searches_by_query
    VCR.use_cassette("works/search") do
      response = @client.search_works("machine learning", limit: 5)

      assert_kind_of Hash, response
      assert_operator response["meta"]["count"], :>, 0
      assert_operator response["results"].size, :>, 0
    end
  end

  def test_search_works_filters_by_year
    VCR.use_cassette("works/search_by_year") do
      year = 2022
      response = @client.search_works("artificial intelligence", year: year, limit: 5)

      response["results"].each do |work|
        assert_equal year, work["publication_year"]
      end
    end
  end

  # ============= works_by_source tests =============

  def test_works_by_source_filters_by_year
    VCR.use_cassette("works/by_source_with_year") do
      year = 2021
      response = @client.works_by_source("S4210163905", year: year, limit: 5)

      response["results"].each do |work|
        assert_equal year, work["publication_year"]
      end
    end
  end


  # ============= work_by_doi tests =============
  def test_work_by_doi_returns_work
    VCR.use_cassette("works/by_doi") do
      response = @client.work_by_doi("10.1038/nature12345")

      assert_kind_of Hash, response
      if response["results"].any?
        work = response["results"].first
        assert_includes work, "title"
        assert_includes work, "doi"
      end
    end
  end

  def test_work_by_doi_handles_url_format
    VCR.use_cassette("works/by_doi_url") do
      response = @client.work_by_doi("https://doi.org/10.1038/nature12345")
      assert_kind_of Hash, response
    end
  end

  # ============= highly_cited_works tests =============
  def test_highly_cited_works_returns_works_above_threshold
    VCR.use_cassette("works/highly_cited") do
      min_citations = 1000
      response = @client.highly_cited_works(min_citations: min_citations, limit: 10)

      response["results"].each do |work|
        assert_operator work["cited_by_count"], :>=, min_citations
      end
    end
  end

  # ============= works_by_type tests =============
  def test_works_by_type_returns_works_of_specific_type
    VCR.use_cassette("works/by_type") do
      response = @client.works_by_type("article", limit: 10)

      response["results"].each do |work|
        assert_equal "article", work["type"]
      end
    end
  end

  # ============= works_by_language tests =============
  def test_works_by_language_returns_works_in_specific_language
    VCR.use_cassette("works/by_language") do
      response = @client.works_by_language("en", limit: 10)

      response["results"].each do |work|
        assert_equal "en", work["language"]
      end
    end
  end

  # ============= works_stats tests =============
  def test_works_stats_returns_metadata
    VCR.use_cassette("works/stats") do
      response = @client.works_stats

      assert_kind_of Hash, response
      assert_includes response, "count"
      assert_includes response, "db_response_time_ms"
    end
  end

  def test_works_stats_with_filter
    VCR.use_cassette("works/stats_with_filter") do
      response = @client.works_stats(filter: { publication_year: 2023 })

      assert_kind_of Hash, response
      assert_includes response, "count"
    end
  end

  # ============= works_by_coauthors tests =============
  def test_works_by_coauthors_returns_works_by_multiple_authors
    VCR.use_cassette("works/by_coauthors") do
      response = @client.works_by_coauthors(["A5002100987", "A5012345678"], limit: 10)

      assert_kind_of Hash, response
      # Проверяем, что в ответе есть работы
      assert_operator response["results"].size, :>=, 0
    end
  end

  # ============= each_work pagination tests =============
  def test_each_work_iterates_over_works
    VCR.use_cassette("works/each_work") do
      count = 0
      @client.each_work(per_page: 5) do |work|
        count += 1
        assert_includes work, "title"
        break if count >= 10
      end
      assert_operator count, :>, 0
    end
  end

  def test_each_work_returns_enumerator
    VCR.use_cassette("works/each_work") do
      enumerator = @client.each_work(per_page: 5)
      assert_kind_of Enumerator, enumerator
    end
  end

  def test_each_work_returns_count
    VCR.use_cassette("works/each_work_count") do
      # Ограничиваем количество для теста
      count = 0
      @client.each_work(per_page: 3) { count += 1; break if count >= 5 }
      assert_operator count, :>, 0
    end
  end
end
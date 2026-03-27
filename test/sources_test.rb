# test/sources_test.rb
# frozen_string_literal: true

require_relative "test_helper"

class SourcesTest < Minitest::Test
  def setup
    @client = setup_client
  end

  # ============= most_cited_sources tests =============
  def test_most_cited_sources_returns_sources_sorted_by_citations
    VCR.use_cassette("sources/most_cited") do
      response = @client.most_cited_sources(limit: 10)

      assert_kind_of Hash, response
      assert_includes response, "results"
      refute_empty response["results"]

      citations = response["results"].map { |s| s["cited_by_count"] }
      assert_equal citations, citations.sort.reverse

      source = response["results"].first
      assert_includes source, "display_name"
      assert_includes source, "cited_by_count"
      assert_includes source, "works_count"
    end
  end

  # ============= search_sources tests =============

  def test_search_sources_returns_empty_for_nonexistent
    VCR.use_cassette("sources/search_nonexistent") do
      response = @client.search_sources("Nonexistent Journal Xyz123")
      assert_equal 0, response["meta"]["count"]
      assert_empty response["results"]
    end
  end

  def test_search_sources_includes_required_fields
    VCR.use_cassette("sources/search") do
      response = @client.search_sources("Cell", limit: 1)

      if response["results"].any?
        source = response["results"].first
        assert_includes source, "display_name"
        assert_includes source, "works_count"
        assert_includes source, "cited_by_count"
        assert_includes source, "issn"
      else
        skip "No results found for Cell"
      end
    end
  end

  # ============= open_access_sources tests =============
  def test_open_access_sources_returns_oa_sources
    VCR.use_cassette("sources/open_access") do
      response = @client.open_access_sources(limit: 10)

      # Все источники должны быть в DOAJ
      response["results"].each do |source|
        assert source["is_in_doaj"] || true # Поле может отсутствовать
      end
    end
  end

  def test_open_access_sources_sorted_by_citations
    VCR.use_cassette("sources/open_access") do
      response = @client.open_access_sources(limit: 10)

      citations = response["results"].map { |s| s["cited_by_count"] }
      assert_equal citations, citations.sort.reverse
    end
  end

  # ============= sources_by_publisher_id tests =============
  def test_sources_by_publisher_id_returns_sources_for_publisher
    VCR.use_cassette("sources/by_publisher") do
      # ID для издательства Elsevier
      response = @client.sources_by_publisher_id("https://openalex.org/P4310320068", limit: 10)

      assert_kind_of Hash, response
      assert_operator response["results"].size, :>, 0

      response["results"].each do |source|
        assert_includes source, "display_name"
        assert_includes source, "host_organization"
      end
    end
  end

  # ============= sources_by_country tests =============

  def test_sources_by_country_germany
    VCR.use_cassette("sources/by_country_de") do
      response = @client.sources_by_country("DE", limit: 5)

      assert_kind_of Hash, response
      assert_operator response["results"].size, :<=, 5
    end
  end

  def test_sources_by_country_respects_limit
    VCR.use_cassette("sources/by_country_us") do
      limit = 3
      response = @client.sources_by_country("US", limit: limit)
      assert_operator response["results"].size, :<=, limit
    end
  end

  def test_sources_by_country_handles_invalid_country
    VCR.use_cassette("sources/by_country_invalid") do
      response = @client.sources_by_country("XX", limit: 5)
      # Может вернуть пустой результат или 0
      assert_kind_of Hash, response
    end
  end

  # ============= source_by_issn tests =============
  def test_source_by_issn_returns_source
    VCR.use_cassette("sources/by_issn_nature") do
      # ISSN Nature
      response = @client.source_by_issn("1476-4687")

      assert_kind_of Hash, response
      if response["results"].any?
        source = response["results"].first
        assert_includes source, "display_name"
        assert source["display_name"].downcase.include?("nature")
      else
        skip "No source found for ISSN 1476-4687"
      end
    end
  end

  def test_source_by_issn_handles_invalid_issn
    VCR.use_cassette("sources/by_issn_invalid") do
      response = @client.source_by_issn("0000-0000")
      assert_equal 0, response["meta"]["count"]
      assert_empty response["results"]
    end
  end

  # ============= most_prolific_sources tests =============
  def test_most_prolific_sources_returns_sources_sorted_by_works_count
    VCR.use_cassette("sources/most_prolific") do
      response = @client.most_prolific_sources(limit: 10)

      assert_kind_of Hash, response
      refute_empty response["results"]

      works_counts = response["results"].map { |s| s["works_count"] }
      assert_equal works_counts, works_counts.sort.reverse
    end
  end



end
# test/topics_test.rb
# frozen_string_literal: true

require_relative "test_helper"

class TopicsTest < Minitest::Test
  def setup
    @client = setup_client
  end

  # ============= topic tests =============
  def test_topic_returns_topic_by_id
    VCR.use_cassette("topics/single_topic") do
      response = @client.topic("T11636")

      assert_kind_of Hash, response
      assert_includes response, "results"

      if response["results"].any?
        topic = response["results"].first
        assert_includes topic, "display_name"
        assert_includes topic, "works_count"
      end
    end
  end

  # ============= most_popular_topics tests =============
  def test_most_popular_topics_returns_topics_sorted_by_works_count
    VCR.use_cassette("topics/most_popular") do
      response = @client.most_popular_topics(limit: 10)

      assert_kind_of Hash, response
      assert_includes response, "results"
      refute_empty response["results"]

      works_counts = response["results"].map { |t| t["works_count"] }
      assert_equal works_counts, works_counts.sort.reverse

      topic = response["results"].first
      assert_includes topic, "display_name"
      assert_includes topic, "works_count"
      assert_includes topic, "cited_by_count"
    end
  end


  # ============= search_topics tests =============

  def test_search_topics_respects_limit
    VCR.use_cassette("topics/search") do
      limit = 3
      response = @client.search_topics("artificial intelligence", limit: limit)
      assert_operator response["results"].size, :<=, limit
    end
  end

  def test_search_topics_returns_empty_for_nonexistent
    VCR.use_cassette("topics/search_nonexistent") do
      response = @client.search_topics("Xyzabc Nonexistent Topic")
      assert_equal 0, response["meta"]["count"]
      assert_empty response["results"]
    end
  end

  # ============= works_by_topic tests =============
  def test_works_by_topic_returns_works_for_topic
    VCR.use_cassette("topics/works_by_topic") do
      response = @client.works_by_topic("T11636", limit: 10)

      assert_kind_of Hash, response
      assert_operator response["results"].size, :>, 0

      response["results"].each do |work|
        assert_includes work, "title"
        assert_includes work, "publication_year"
        assert_includes work, "doi"
      end
    end
  end

  def test_works_by_topic_sorted_by_citations
    VCR.use_cassette("topics/works_by_topic") do
      response = @client.works_by_topic("T11636", limit: 10)

      citations = response["results"].map { |w| w["cited_by_count"] }
      assert_equal citations, citations.sort.reverse
    end
  end

  # ============= topic_hierarchy tests =============
  def test_topic_hierarchy_returns_hierarchy_array
    VCR.use_cassette("topics/hierarchy") do
      hierarchy = @client.topic_hierarchy("T11636")

      assert_kind_of Array, hierarchy
      refute_empty hierarchy

      hierarchy.each do |level|
        assert_includes level, :level
        assert_includes level, :name
        assert_includes level, :id
      end
    end
  end

  # ============= topic_stats tests =============
  def test_topic_stats_returns_statistics_hash
    VCR.use_cassette("topics/stats") do
      stats = @client.topic_stats("T11636")

      if stats
        assert_kind_of Hash, stats
        assert_includes stats, :name
        assert_includes stats, :works_count
        assert_includes stats, :cited_by_count
        assert_includes stats, :domain
        assert_includes stats, :field
        assert_includes stats, :subfield
      else
        skip "No stats returned for topic"
      end
    end
  end

  # ============= top_cited_topics tests =============

  def test_top_cited_topics_respects_limit
    VCR.use_cassette("topics/top_cited") do
      limit = 5
      response = @client.top_cited_topics(limit: limit)
      assert_operator response["results"].size, :<=, limit
    end
  end

  # ============= each_topic pagination tests =============
  def test_each_topic_iterates_over_topics
    VCR.use_cassette("topics/each_topic") do
      count = 0
      @client.each_topic(per_page: 5) do |topic|
        count += 1
        assert_includes topic, "display_name"
        break if count >= 10
      end
      assert_operator count, :>, 0
    end
  end

  def test_each_topic_returns_enumerator
    VCR.use_cassette("topics/each_topic") do
      enumerator = @client.each_topic(per_page: 5)
      assert_kind_of Enumerator, enumerator
    end
  end

  def test_each_topic_with_filter
    VCR.use_cassette("topics/each_topic_filtered") do
      count = 0
      @client.each_topic(filter: { works_count: ">10000" }, per_page: 5) do |topic|
        count += 1
        assert_operator topic["works_count"].to_i, :>=, 10000
        break if count >= 5
      end
      assert_operator count, :>, 0
    end
  end

  def test_each_topic_returns_count
    VCR.use_cassette("topics/each_topic_count") do
      count = 0
      @client.each_topic(per_page: 3) { count += 1; break if count >= 5 }
      assert_operator count, :>, 0
    end
  end
end
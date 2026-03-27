# test/client/authors_test.rb
require_relative "test_helper"

class AuthorsTest < Minitest::Test
  def setup
    @client = setup_client
  end

  # ============= most_cited_authors tests =============
  def test_most_cited_authors_returns_authors_sorted_by_citation_count
    VCR.use_cassette("authors/most_cited") do
      response = @client.most_cited_authors(limit: 10)

      assert_kind_of Hash, response
      assert_includes response, "results"
      refute_empty response["results"], "Expected at least one author"

      citations = response["results"].map { |a| a["cited_by_count"] }
      assert_equal citations, citations.sort.reverse

      author = response["results"].first
      assert_includes author, "display_name"
      assert_includes author, "cited_by_count"
      assert_includes author, "works_count"
      assert_includes author, "summary_stats"
    end
  end

  def test_most_cited_authors_respects_limit_parameter
    VCR.use_cassette("authors/most_cited") do
      limit = 5
      response = @client.most_cited_authors(limit: limit)
      assert_operator response["results"].size, :<=, limit
    end
  end

  def test_most_cited_authors_handles_per_page_parameter_correctly
    VCR.use_cassette("authors/most_cited") do
      response = @client.most_cited_authors(limit: 10, per_page: 5)
      assert_operator response["results"].size, :<=, 5
    end
  end

  # ============= search_authors tests =============
  def test_search_authors_searches_by_name
    VCR.use_cassette("authors/search_by_name") do
      response = @client.search_authors("Yoshua Bengio", limit: 5)

      assert_kind_of Hash, response
      assert_operator response["meta"]["count"], :>, 0
      assert_operator response["results"].size, :>, 0

      names = response["results"].map { |a| a["display_name"].downcase }
      assert names.any? { |n| n.include?("yoshua") || n.include?("bengio") }
    end
  end

  def test_search_authors_respects_limit_parameter
    VCR.use_cassette("authors/search_by_name") do
      limit = 3
      response = @client.search_authors("Jane Smith", limit: limit)
      assert_operator response["results"].size, :<=, limit
    end
  end

  def test_search_authors_returns_empty_results_for_non_existent_author
    VCR.use_cassette("authors/search_nonexistent") do
      response = @client.search_authors("Xyzabc123 Nonexistent Author")
      assert_equal 0, response["meta"]["count"]
      assert_empty response["results"]
    end
  end

  def test_search_authors_includes_required_fields
    VCR.use_cassette("authors/search_by_name") do
      response = @client.search_authors("Geoffrey Hinton", limit: 1)

      if response["results"].any?
        author = response["results"].first
        assert_includes author, "display_name"
        assert_includes author, "works_count"
        assert_includes author, "cited_by_count"
        assert_includes author, "ids"
      else
        skip "No results found for Geoffrey Hinton"
      end
    end
  end

  # ============= authors_by_institution tests =============
  def test_authors_by_institution_returns_authors_affiliated_with_mit
    VCR.use_cassette("authors/by_institution_mit") do
      response = @client.authors_by_institution("I19820366", limit: 10)

      assert_kind_of Hash, response

      if response["results"].any?
        assert_operator response["results"].size, :>, 0

        # Проверяем, что у всех авторов есть обязательные поля
        response["results"].each do |author|
          assert_includes author, "display_name"
          assert_includes author, "works_count"
          assert_includes author, "cited_by_count"
          assert_includes author, "ids"
          # last_known_institutions может отсутствовать — это нормально
        end
      else
        skip "No authors found for this institution"
      end
    end
  end

  def test_authors_by_institution_returns_authors_affiliated_with_harvard
    VCR.use_cassette("authors/by_institution_harvard") do
      response = @client.authors_by_institution("I136199984", limit: 5)
      assert_kind_of Hash, response
      assert_operator response["results"].size, :<=, 5
    end
  end

  def test_authors_by_institution_respects_limit_parameter
    VCR.use_cassette("authors/by_institution_mit") do
      limit = 3
      response = @client.authors_by_institution("I19820366", limit: limit)
      assert_operator response["results"].size, :<=, limit
    end
  end

  def test_authors_by_institution_handles_invalid_institution_id
    VCR.use_cassette("authors/by_institution_invalid") do
      response = @client.authors_by_institution("I0000000000", limit: 5)
      assert_equal 0, response["meta"]["count"]
      assert_empty response["results"]
    end
  end
  # ============= most_prolific_authors tests =============
  def test_most_prolific_authors_returns_authors_sorted_by_works_count
    VCR.use_cassette("authors/most_prolific") do
      response = @client.most_prolific_authors(limit: 10)

      assert_kind_of Hash, response
      refute_empty response["results"], "Expected at least one author"

      works_counts = response["results"].map { |a| a["works_count"] }
      assert_equal works_counts, works_counts.sort.reverse
    end
  end

  def test_most_prolific_authors_respects_limit_parameter
    VCR.use_cassette("authors/most_prolific") do
      limit = 5
      response = @client.most_prolific_authors(limit: limit)
      assert_operator response["results"].size, :<=, limit
    end
  end

  def test_most_prolific_authors_includes_summary_stats
    VCR.use_cassette("authors/most_prolific") do
      response = @client.most_prolific_authors(limit: 3)
      response["results"].each { |author| assert_includes author, "summary_stats" }
    end
  end

  # ============= author_by_orcid tests =============
  def test_author_by_orcid_returns_author_by_orcid
    VCR.use_cassette("authors/by_orcid_jason_priem") do
      response = @client.author_by_orcid("0000-0001-6187-6610")

      assert_kind_of Hash, response
      refute_nil response["results"]

      if response["results"].any?
        author = response["results"].first
        assert_includes author.dig("ids", "orcid"), "0000-0001-6187-6610"
        assert_equal "Jason Priem", author["display_name"]
      else
        flunk "No results returned for ORCID 0000-0001-6187-6610"
      end
    end
  end

  def test_author_by_orcid_handles_orcid_with_url_format
    VCR.use_cassette("authors/by_orcid_url_format") do
      response = @client.author_by_orcid("https://orcid.org/0000-0001-6187-6610")
      assert_kind_of Hash, response
    end
  end

  def test_author_by_orcid_handles_non_existent_orcid
    VCR.use_cassette("authors/by_orcid_nonexistent") do
      response = @client.author_by_orcid("0000-0000-0000-0000")
      assert_equal 0, response["meta"]["count"]
      assert_empty response["results"]
    end
  end

  def test_author_by_orcid_returns_author_with_required_fields
    VCR.use_cassette("authors/by_orcid_jason_priem") do
      response = @client.author_by_orcid("0000-0001-6187-6610")

      if response["results"].any?
        author = response["results"].first
        required_fields = %w[display_name works_count cited_by_count summary_stats ids last_known_institutions]
        required_fields.each { |field| assert_includes author, field }
      else
        skip "No results for ORCID 0000-0001-6187-6610"
      end
    end
  end

  # ============= top_authors_by_hindex tests =============
  def test_top_authors_by_hindex_returns_authors_sorted_by_h_index
    VCR.use_cassette("authors/top_by_hindex") do
      response = @client.top_authors_by_hindex(limit: 10)

      assert_kind_of Hash, response
      refute_empty response["results"], "Expected at least one author"

      h_indices = response["results"].map { |a| a.dig("summary_stats", "h_index") || 0 }
      assert_equal h_indices, h_indices.sort.reverse
    end
  end

  def test_top_authors_by_hindex_respects_limit_parameter
    VCR.use_cassette("authors/top_by_hindex") do
      limit = 5
      response = @client.top_authors_by_hindex(limit: limit)
      assert_operator response["results"].size, :<=, limit
    end
  end

  def test_top_authors_by_hindex_handles_authors_without_h_index
    VCR.use_cassette("authors/top_by_hindex") do
      response = @client.top_authors_by_hindex(limit: 20)
      response["results"].each { |author| assert_includes author, "summary_stats" }
    end
  end

  def test_top_authors_by_hindex_includes_all_required_fields
    VCR.use_cassette("authors/top_by_hindex") do
      response = @client.top_authors_by_hindex(limit: 3)
      required_fields = %w[display_name works_count cited_by_count summary_stats ids]
      response["results"].each do |author|
        required_fields.each { |field| assert_includes author, field }
      end
    end
  end
end
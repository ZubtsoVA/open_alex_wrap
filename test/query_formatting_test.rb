# test/query_formatting_test.rb
require_relative "test_helper"

class QueryFormattingTest < Minitest::Test
  def setup
    @client = setup_client  # ← Инициализируем @client из test_helper
  end
  # ============= format_filter tests =============
  def test_format_filter_with_hash_single
    filter = { publication_year: 2024 }
    result = @client.format_filter(filter)
    assert_equal "publication_year:2024", result
  end

  def test_format_filter_with_hash_multiple
    filter = { publication_year: 2024, open_access: true }
    result = @client.format_filter(filter)
    assert_equal "publication_year:2024,open_access:true", result
  end

  def test_format_filter_with_string
    filter_string = "publication_year:2024"
    result = @client.format_filter(filter_string)
    assert_equal filter_string, result
  end

  def test_format_filter_with_complex_operators
    filter = { cited_by_count: ">100", publication_year: "2020-2024" }
    result = @client.format_filter(filter)
    assert_equal "cited_by_count:>100,publication_year:2020-2024", result
  end

  def test_format_filter_with_empty_hash
    filter = {}
    result = @client.format_filter(filter)
    assert_equal "", result
  end

  def test_format_filter_with_nil
    result = @client.format_filter(nil)
    assert_equal "", result
  end

  # ============= format_sort tests =============
  def test_format_sort_with_hash_single
    sort = { cited_by_count: :desc }
    result = @client.format_sort(sort)
    assert_equal "cited_by_count:desc", result
  end

  def test_format_sort_with_hash_multiple
    sort = { cited_by_count: :desc, publication_date: :asc }
    result = @client.format_sort(sort)
    assert_equal "cited_by_count:desc,publication_date:asc", result
  end

  def test_format_sort_with_string
    sort_string = "cited_by_count:desc"
    result = @client.format_sort(sort_string)
    assert_equal sort_string, result
  end

  def test_format_sort_with_empty_hash
    sort = {}
    result = @client.format_sort(sort)
    assert_equal "", result
  end

  # ============= format_select tests =============
  def test_format_select_with_array
    select = ["id", "title", "doi"]
    result = @client.format_select(select)
    assert_equal "id,title,doi", result
  end

  def test_format_select_with_array_of_symbols
    select = [:id, :title, :doi]
    result = @client.format_select(select)
    assert_equal "id,title,doi", result
  end

  def test_format_select_with_single_field_array
    select = ["title"]
    result = @client.format_select(select)
    assert_equal "title", result
  end

  def test_format_select_with_hash_single_resource
    select = { work: [:id, :title] }
    result = @client.format_select(select)
    assert_equal "work.id,work.title", result
  end

  def test_format_select_with_hash_multiple_resources
    select = {
      work: [:id, :title],
      author: [:name, :orcid]
    }
    result = @client.format_select(select)
    assert_equal "work.id,work.title,author.name,author.orcid", result
  end

  def test_format_select_with_hash_string_field
    select = { work: "title" }
    result = @client.format_select(select)
    assert_equal "work.title", result
  end

  def test_format_select_with_string
    select_string = "id,title,doi"
    result = @client.format_select(select_string)
    assert_equal select_string, result
  end

  def test_format_select_with_nil
    result = @client.format_select(nil)
    assert_nil result
  end

  def test_format_select_with_symbol
    select = :title
    result = @client.format_select(select)
    assert_equal "title", result
  end
end
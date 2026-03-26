$LOAD_PATH.unshift File.expand_path("..", __dir__)

require_relative "test_helper"

class QueryFormattingTest < Minitest::Test
  def setup
    @client = setup_client
  end

  # ============= format_filter tests =============
  describe "#format_filter" do
    it "formats Hash with single key-value pair" do
      filter = { publication_year: 2024 }
      result = @client.send(:format_filter, filter)
      assert_equal "publication_year:2024", result
    end

    it "formats Hash with multiple key-value pairs" do
      filter = { publication_year: 2024, open_access: true }
      result = @client.send(:format_filter, filter)
      assert_equal "publication_year:2024,open_access:true", result
    end

    it "returns string unchanged" do
      filter_string = "publication_year:2024,open_access:true"
      result = @client.send(:format_filter, filter_string)
      assert_equal filter_string, result
    end

    it "handles complex operators" do
      filter = { cited_by_count: ">100", publication_year: "2020-2024" }
      result = @client.send(:format_filter, filter)
      assert_equal "cited_by_count:>100,publication_year:2020-2024", result
    end

    it "handles empty Hash" do
      filter = {}
      result = @client.send(:format_filter, filter)
      assert_equal "", result
    end
  end

  # ============= format_sort tests =============
  describe "#format_sort" do
    it "formats Hash with single sort criterion" do
      sort = { cited_by_count: :desc }
      result = @client.send(:format_sort, sort)
      assert_equal "cited_by_count:desc", result
    end

    it "formats Hash with multiple sort criteria" do
      sort = { cited_by_count: :desc, publication_date: :asc }
      result = @client.send(:format_sort, sort)
      assert_equal "cited_by_count:desc,publication_date:asc", result
    end

    it "returns string unchanged" do
      sort_string = "cited_by_count:desc,publication_date:asc"
      result = @client.send(:format_sort, sort_string)
      assert_equal sort_string, result
    end

    it "handles empty Hash" do
      sort = {}
      result = @client.send(:format_sort, sort)
      assert_equal "", result
    end
  end

  # ============= format_select tests =============
  describe "#format_select" do
    it "formats Array with multiple fields" do
      select = ["id", "title", "doi"]
      result = @client.send(:format_select, select)
      assert_equal "id,title,doi", result
    end

    it "formats Hash with single resource" do
      select = { work: [:id, :title] }
      result = @client.send(:format_select, select)
      assert_equal "work.id,work.title", result
    end

    it "formats Hash with multiple resources" do
      select = {
        work: [:id, :title],
        author: [:name, :orcid]
      }
      result = @client.send(:format_select, select)
      assert_equal "work.id,work.title,author.name,author.orcid", result
    end

    it "returns string unchanged" do
      select_string = "id,title,doi"
      result = @client.send(:format_select, select_string)
      assert_equal select_string, result
    end

    it "returns nil for nil input" do
      result = @client.send(:format_select, nil)
      assert_nil result
    end

    it "converts Symbol to string" do
      select = :title
      result = @client.send(:format_select, select)
      assert_equal "title", result
    end
  end
end
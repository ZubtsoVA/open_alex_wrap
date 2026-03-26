# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "open_alex_wrap"

require "minitest/autorun"
require "minitest/unit"
require "vcr"
require "webmock/minitest"



VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock

  # Фильтруем чувствительные данные
  config.filter_sensitive_data("<OPENALEX_EMAIL>") { ENV["OPENALEX_EMAIL"] || "test@example.com" }
  config.filter_sensitive_data("<OPENALEX_API_KEY>") { ENV["OPENALEX_API_KEY"] || "fake_key" }

  config.default_cassette_options = {
    record: :once,
    match_requests_on: [:method, :uri]
  }
end



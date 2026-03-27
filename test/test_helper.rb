# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require_relative "../lib/open_alex_wrap"

require "minitest/autorun"
require "minitest/unit"
require "vcr"
require "webmock/minitest"

module TestHelpers
  def setup_client
    # Проверка, что гем загружен
    puts "Creating client with email: #{ENV['OPENALEX_EMAIL'] || 'test@example.com'}"

    client = OpenAlexWrap::Client.new(
      email: ENV["OPENALEX_EMAIL"] || "test@example.com",
      api_key: ENV["OPENALEX_API_KEY"]
    )

    # Проверка, что клиент создан
    puts "Client created: #{client.inspect}"
    puts "Client methods: #{client.methods.sort.grep(/most_cited/)}"

    client
  end
end

# Включаем хелперы в Minitest::Test
class Minitest::Test
  include TestHelpers
end



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



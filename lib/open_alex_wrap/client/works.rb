# frozen_string_literal: true

# TODO: Методы для поиска конкретных работ (works)

module OpenAlexWrap
  module Works
    def work(id)
      response = @conn.get("/works/#{id}")
      if response.status == 200
        parse_work(response.body)
      else
        # нужно будет прописать ошибки 404 и 429
        nil
      end
    end
    private
    def works(params = {})
      @conn.get("/works", params)
    end
  end
end
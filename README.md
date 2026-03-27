# OpenAlexWrap

Ruby-обёртка для [OpenAlex API](https://openalex.org/), предоставляющая чистый и интуитивно понятный интерфейс для доступа к метаданным научных публикаций — работам, авторам, источникам и темам.

## Возможности

- **Поиск работ, авторов, источников и тем** с гибкой фильтрацией
- **Получение наиболее цитируемых/продуктивных сущностей** с настраиваемыми лимитами
- **Поиск по идентификаторам** — DOI, ORCID, ISSN и др.
- **Пагинация на основе курсоров** для итерации по большим наборам данных
- **Простой Ruby-подобный синтаксис**

## Установка

Добавьте в `Gemfile`:

```ruby
gem 'open_alex_wrap'
```

Затем выполните:

```bash
bundle install
```

Или установите напрямую:

```bash
gem install open_alex_wrap
```

Если вы клонируете репозиторий и не хотите устанавливать development-зависимости (minitest, vcr, webmock, rubocop и др.):

```bash
git clone https://github.com/ZubtsoVA/open_alex_wrap.git
cd open_alex_wrap
bundle install --without development
```

## Использование

### Инициализация клиента

```ruby
require 'open_alex_wrap'

client = OpenAlexWrap::Client.new(
  email: 'your-email@example.com',  # обязательно
  api_key: 'your-api-key',          # опционально, повышает лимиты запросов
  timeout: 10                        # опционально, по умолчанию 10 секунд
)
```

---

### Работы (Works)

```ruby
# Наиболее цитируемые работы всех времён
most_cited = client.most_cited_works(limit: 10)

# Наиболее цитируемые работы за 2023 год
most_cited_2023 = client.most_cited_works(year: 2023, limit: 20)

# Поиск работ по ключевым словам
ai_works = client.search_works('artificial intelligence', limit: 50)

# Поиск с фильтрами
oa_ml = client.search_works('machine learning', open_access: true, limit: 30)

# Получить работу по DOI
work = client.work_by_doi('10.1038/s41586-020-2649-2')

# Работы конкретного автора
author_works = client.works_by_author('A123456789', limit: 100)

# Работы из конкретного журнала
nature_works = client.works_by_source('S123456789', year: 2024, limit: 50)

# Работы в открытом доступе
oa_works = client.open_access_works(year: 2023, limit: 100)

# Высокоцитируемые работы
highly_cited = client.highly_cited_works(min_citations: 500, year: 2022)

# Итерация по всем работам с курсорной пагинацией
count = 0
client.each_work(filter: { publication_year: 2023 }) do |work|
  count += 1
  puts work['title']
end
puts "Total works: #{count}"
```

---

### Авторы (Authors)

```ruby
# Наиболее цитируемые авторы
top_authors = client.most_cited_authors(limit: 50)

# Наиболее продуктивные авторы (по числу работ)
prolific = client.most_prolific_authors(limit: 30)

# Поиск авторов по имени
smith_authors = client.search_authors('John Smith', limit: 20)

# Авторы из конкретного института
harvard_authors = client.authors_by_institution('I123456789', limit: 100)

# Получить автора по ORCID
author = client.author_by_orcid('0000-0000-0000-0000')

# Топ авторов по h-index (сортировка на стороне клиента)
top_hindex = client.top_authors_by_hindex(limit: 100)
```

---

### Источники (Sources)

```ruby
# Наиболее цитируемые источники
top_journals = client.most_cited_sources(limit: 50)

# Поиск источников по названию
science_journals = client.search_sources('science', limit: 30)

# Источники в открытом доступе (из DOAJ)
oa_journals = client.open_access_sources(limit: 50)

# Источники конкретного издателя
elsevier_sources = client.sources_by_publisher_id('P4310320068', limit: 30)

# Источники по стране
us_journals = client.sources_by_country('US', limit: 100)

# Получить источник по ISSN
nature = client.source_by_issn('1476-4687')

# Наиболее продуктивные источники (по числу работ)
most_papers = client.most_prolific_sources(limit: 50)
```

---

### Темы (Topics)

```ruby
# Получить тему по ID
topic = client.topic('T11636')

# Наиболее популярные темы (по числу работ)
popular = client.most_popular_topics(limit: 50)

# Поиск тем по названию
ml_topics = client.search_topics('machine learning', limit: 30)

# Работы по теме
topic_works = client.works_by_topic('T11636', limit: 100)

# Темы по домену (Physical Sciences, Life Sciences и т.д.)
physical_sciences = client.topics_by_domain('D1', limit: 50)

# Иерархия темы (домен → поле → субполе → тема)
hierarchy = client.topic_hierarchy('T11636')
hierarchy.each do |level|
  puts "#{level[:level]}: #{level[:name]}"
end

# Статистика по теме
stats = client.topic_stats('T11636')
puts "Works: #{stats[:works_count]}"
puts "Citations: #{stats[:cited_by_count]}"
puts "Domain: #{stats[:domain]}"

# Итерация по темам с фильтрацией
client.each_topic(filter: { works_count: '>1000' }) do |topic|
  puts "#{topic['display_name']}: #{topic['works_count']} works"
end
```

---

### Расширенный запрос (низкоуровневое API)

Метод `query` доступен напрямую и поддерживает все параметры OpenAlex API.

**Фильтры:**

```ruby
# Hash-формат (рекомендуется)
client.query(:work, filter: { publication_year: 2023, open_access: true })

# String-формат
client.query(:work, filter: 'publication_year:2023,open_access:true')
```

**Сортировка:**

```ruby
# Hash-формат
client.query(:work, sort: { cited_by_count: :desc, publication_date: :asc })

# String-формат
client.query(:work, sort: 'cited_by_count:desc,publication_date:asc')
```

**Выбор полей** (повышает производительность):

```ruby
# Array-формат
client.query(:work, select: ['title', 'doi', 'publication_year'])

# String-формат
client.query(:work, select: 'title,doi,publication_year')
```

**Ручная пагинация с курсорами:**

```ruby
response = client.query(:work, filter: { publication_year: 2023 }, cursor: '*')
while response['results']&.any?
  response['results'].each { |work| puts work['title'] }
  next_cursor = response['meta']['next_cursor']
  break if next_cursor.nil?
  response = client.query(:work, cursor: next_cursor)
end
```

---

## Доступные типы сущностей

| Тип | Символ | Описание |
|-----|--------|----------|
| Works | `:work` | Научные статьи, публикации, книги |
| Authors | `:author` | Исследователи и учёные |
| Sources | `:source` | Журналы и другие источники |
| Topics | `:topic` | Исследовательские темы и концепции |

## Лимиты запросов

OpenAlex API имеет ограничения на количество запросов, некоторые запросы без ключа недосупны. Рекомендуется указывать `email` при инициализации клиента (полиси вежливости) и использовать `api_key`. api ключ можно получить на https://openalex.org/settings/api-key

## Ссылки

- [OpenAlex API Documentation](https://docs.openalex.org/)
- [GitHub Repository](https://github.com/ZubtsoVA/open_alex_wrap)
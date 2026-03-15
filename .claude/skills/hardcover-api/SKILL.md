---
name: hardcover-api
description: Reference for working with the Hardcover GraphQL API in this project. Use when writing or modifying Hardcover API queries, Jekyll plugins that call Hardcover, or debugging data issues. Includes tested queries, known quirks, field reference, and the existing plugin architecture.
user-invocable: true
allowed-tools: Bash, Read, Edit, Write
---

# Hardcover API Reference

The official docs at https://docs.hardcover.app/api/getting-started/ are **incomplete and not fully trustworthy**. Trust this file and empirical testing over the docs.

## Endpoint & Auth

- **Endpoint:** `https://api.hardcover.app/v1/graphql` (POST)
- **Auth header:** `Authorization: <token>` (the token already includes the `Bearer ` prefix — do not add it again)
- **Token location:** `.env` → `HARDCOVER_TOKEN`
- **SSL:** Must set `verify_mode = OpenSSL::SSL::VERIFY_NONE` in Ruby — the server does not pass standard SSL verification

## Critical Quirks

- `me` returns an **array**, not a single object. Always index with `me[0]` (e.g., `result.dig("data", "me", 0, ...)`).
- `finished_at` and `started_at` on `user_book_reads` are **often null** even for fully read books. Use `last_read_date` on `user_books` as the primary date field.
- `last_read_date` can also be null for older entries — fall back to `date_added`.
- `rating` is a float (0.5 increments, e.g. `3.5`, `4.0`) or null.
- The token value stored in `.env` already contains `Bearer `, e.g. `HARDCOVER_TOKEN=Bearer eyJ...`

## Book Status IDs

| status_id | Meaning |
|-----------|---------|
| 1 | Want to Read |
| 2 | Currently Reading |
| 3 | Read |

## Tested Queries

### Verify auth
```graphql
query Test {
  me {
    username
  }
}
```

### Count read books
```graphql
query CountReadBooks {
  me {
    user_books_aggregate(where: {status_id: {_eq: 3}}) {
      aggregate { count }
    }
  }
}
```

### All read books (full data, sorted by date)
```graphql
query AllReadBooks {
  me {
    user_books(
      where: {status_id: {_eq: 3}},
      limit: 500,
      order_by: {last_read_date: desc_nulls_last}
    ) {
      id
      rating
      last_read_date
      date_added
      user_book_reads {
        started_at
        finished_at
        edition {
          id
          title
          image { url }
          contributions {
            author { name }
          }
        }
      }
      book { id title }
    }
  }
}
```

### Currently reading books
```graphql
query BooksCurrentlyReading {
  me {
    user_books(where: {status_id: {_eq: 2}}) {
      user_book_reads {
        edition {
          title
          image { url }
          contributions { author { name } }
        }
      }
    }
  }
}
```

## Data Shape (user_books entry)

```
user_book
  ├── id                          # user_book ID (int)
  ├── rating                      # float or null
  ├── last_read_date              # "YYYY-MM-DD" or null  ← best date field
  ├── date_added                  # "YYYY-MM-DD"          ← fallback date
  ├── book
  │   ├── id                      # canonical book ID
  │   └── title                   # canonical title
  └── user_book_reads[]           # typically one entry
      ├── started_at              # "YYYY-MM-DD" or null (often null)
      ├── finished_at             # "YYYY-MM-DD" or null (often null)
      └── edition
          ├── id
          ├── title               # edition-specific title (prefer over book.title)
          ├── image
          │   └── url             # JPEG/PNG cover URL from hardcover CDN
          └── contributions[]
              └── author
                  └── name
```

## Deriving a Year for Grouping

```ruby
date_str = user_book["last_read_date"] || read["finished_at"] || user_book["date_added"]
year = date_str ? date_str[0, 4] : "Unknown"
```

## Existing Plugins

| Plugin | Data file | Status queried |
|--------|-----------|----------------|
| `_plugins/hardcover_all_read.rb` | `_data/hardcover_all_read.json` | 3 (read) |
| `_plugins/hardcover_currently_reading.rb` | `_data/hardcover_currently_reading.json` | 2 (currently reading) |

**Key difference in persistence:**
- `hardcover_all_read.json` is **committed to git** — the plugin only overwrites it on a successful API call, so historical data survives even if the API goes down.
- `hardcover_currently_reading.json` is **gitignored** — regenerated fresh each build.

## Image Handling

Cover images are downloaded from the Hardcover CDN and converted to WebP at build time:

```ruby
uri = URI.parse(image_url)
basename = File.basename(uri.path, File.extname(uri.path))
webp_path = File.join(images_dir, "#{basename}.webp")
unless File.exist?(webp_path)
  image = MiniMagick::Image.read(URI.open(image_url))
  image.format "webp"
  image.write webp_path
end
filepath = File.join('assets', 'images', 'hardcover', "#{basename}.webp")
```

Images live in `assets/images/hardcover/` and are **committed to git** for resilience.

## Testing Queries via curl

```sh
TOKEN=$(grep HARDCOVER_TOKEN .env | cut -d= -f2-)
curl -s -X POST https://api.hardcover.app/v1/graphql \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "query Test { me { username } }"}' | python3 -m json.tool
```

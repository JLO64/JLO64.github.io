# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Personal blog for Julian Lopez, built with Jekyll and deployed via Docker. Live at [julianlopez.net](https://www.julianlopez.net). The site title is "Domain of a Knight".

## Tech Stack

- **Static site generator**: Jekyll (Ruby)
- **Styling**: SCSS (compiled to `assets/css/main.css`)
- **Build environment**: Docker (`ruby:3.3.6-alpine`)
- **Deployment**: Manual via `server_build_script.sh` — no CI/CD
- **Book API**: Hardcover (GraphQL)
- **Movie API**: TMDB (REST)
- **Game data**: HowLongToBeat (internal API, no token required)
- **Social feed**: Mastodon/GoToSocial RSS

## Key Directories

| Path | Purpose |
|---|---|
| `_posts/` | Blog posts in Markdown |
| `_layouts/` | Page layout templates |
| `_includes/` | Reusable HTML/JS partials |
| `_plugins/` | Custom Ruby Jekyll generators |
| `_sass/` | SCSS source files |
| `_data/` | Static and auto-generated data files |
| `assets/images/hardcover/` | Book cover images (committed for API resilience) |
| `assets/images/hltb/` | HLTB game cover images (committed for API resilience) |
| `assets/images/tmdb/` | TMDB movie/TV poster images (committed for API resilience) |
| `assets/images/posts/` | Post images with generated thumbnails (committed to git) |

## Custom Plugins (`_plugins/`)

- **`hardcover_all_read.rb`** — Fetches all read books (status_id=3) from Hardcover's GraphQL API at build time. Downloads and converts cover images to WebP. Writes to `_data/hardcover_all_read.json`. Only overwrites the file on a successful API call — falls back to the committed file if the API is unavailable.
- **`hardcover_currently_reading.rb`** — Fetches currently-reading books (status_id=2) from Hardcover's GraphQL API at build time. Requires `HARDCOVER_TOKEN` (or `HARDCOVER_AUTHORIZATION`) env var. Downloads and converts cover images to WebP. Writes to `_data/hardcover_currently_reading.json`.
- **`mal_anime_list.rb`** — Fetches all anime from the public MAL `load.json` endpoint (no API token required) at build time. Downloads and converts cover images to WebP. Writes to `_data/mal_anime_list.json` and `_data/mal_currently_watching.json`. Falls back to existing files on network failure.
- **`mal_manga_list.rb`** — Same as above for manga. Writes to `_data/mal_manga_list.json` and `_data/mal_currently_reading_manga.json`.
- **`mastodon_feed.rb`** — Fetches the latest Mastodon post from the RSS feed at `gotosocial.julianlopez.net`. Downloads and converts images to WebP. Writes to `_data/most_recent_mastodon_post.yml`.
- **`hltb_games_list.rb`** — Fetches all games from HowLongToBeat via the internal `/api/user/{user_id}/games/list` endpoint (no API token required). Maps list flags to status strings (`playing`, `backlog`, `replay`, `on_hold`, `custom2`, `custom3`, `completed`, `retired`). Downloads and converts cover images to WebP. Writes to `_data/hltb_games_list.json` and `_data/hltb_currently_playing.json`. Falls back to committed files on network failure.
- **`tmdb_rated_movies.rb`** — Fetches all rated movies from TMDB's v4 `/account/{object_id}/movie/rated` endpoint at build time. Requires `TMDB_API_KEY` env var. Downloads and converts poster images to WebP. Writes to `_data/tmdb_rated_movies.json` and `_data/tmdb_recently_rated_movies.json`. Groups by `account_rating.created_at` (rating date). Falls back to cached files on network failure. Paginates through all pages automatically.
- **`post_image_thumbnails.rb`** — Scans `assets/images/posts/**/*` for supported image formats (jpg, jpeg, png, gif, webp) and generates 480px-wide WebP thumbnails in a `thumbnails/` subdirectory alongside each original. Skips images that already have a thumbnail. Also copies thumbnails to `_site/` since generators run after static files are copied.
- **`python.rb`** — Pre-processes post links: rewrites `[text](post-name.md)` → `[text]({% post_url post-name %})`.

## Environment Variables

Store in `.env` at the repo root (gitignored).

**Ruby plugins** parse `.env` with `File.foreach` (splitting on `=`), so unquoted values with spaces (e.g., `Bearer eyJhbGci...`) are handled correctly at build time.

**The server script** (`server_build_script.sh`) sources `.env` directly with bash, so values containing spaces **must be quoted**:

```sh
HARDCOVER_TOKEN="Bearer eyJhbGci..."
```

Without quotes, bash interprets the space as a command separator — `HARDCOVER_TOKEN=Bearer` gets set as an env var and the rest of the token is executed as a command, causing a "command not found" error.

| Variable | Purpose |
|---|---|
| `HARDCOVER_TOKEN` | Hardcover API auth token (JWT) |
| `TMDB_API_KEY` | TMDB API Read Access Token (JWT) — pass as `Authorization: Bearer <token>` |
| `MAL_Client_ID` | MAL API client ID — only needed if you want to use the official API directly; not required for the `load.json` scraping approach used by the plugins |

## Build & Deploy

**Local build:**
```sh
bundle exec jekyll build
```
The Hardcover and Mastodon plugins run automatically during build if their env vars and network are available. Both plugins fail silently — a missing token or network error logs a warning but doesn't abort the build.

**Local dev server** (use `/serve` skill):
```sh
bundle exec jekyll serve --port 4000
```
Use `uvx rodney --local` to browse the site programmatically. The `.rodney/` directory is gitignored and excluded from Jekyll's watch list.

**Server deploy** (`server_build_script.sh`):
- Accepts `KEY=VALUE` args or reads from `.env`
- Pulls latest git, builds via Docker **twice**, copies `_site/` to the NGINX directory
- Required args: `JEKYLL_DIR`, `NGINX_DIR`, `HARDCOVER_TOKEN`
- **Why two builds?** Jekyll loads `_data/` before running generator plugins, so files written by plugins (e.g. `hardcover_currently_reading.json`) are only available on the *next* build. The first build fetches and writes the data; the second build renders the site using it.

## Data Files

| File | Committed | Notes |
|---|---|---|
| `_data/hardcover_all_read.json` | Yes | Persisted book history — do not delete |
| `_data/hardcover_currently_reading.json` | No | Regenerated each build |
| `_data/mal_anime_list.json` | Yes | Persisted anime history — do not delete |
| `_data/mal_manga_list.json` | Yes | Persisted manga history — do not delete |
| `_data/mal_currently_watching.json` | No | Regenerated each build |
| `_data/mal_currently_reading_manga.json` | No | Regenerated each build |
| `_data/most_recent_mastodon_post.yml` | No | Regenerated each build |
| `_data/tmdb_rated_movies.json` | No | Regenerated each build |
| `_data/tmdb_recently_rated_movies.json` | No | Regenerated each build |

**Important:** Jekyll loads `_data` files before running generator plugins. A plugin that writes to `_data` is always one build behind — the new data is used in the next build. This is why `hardcover_all_read.json` is committed: it's always present and up-to-date from the previous build.

## Auto-generated Files (do not edit manually)

- `_data/hardcover_currently_reading.json`
- `_data/mal_currently_watching.json`
- `_data/mal_currently_reading_manga.json`
- `_data/most_recent_mastodon_post.yml`
- `_data/tmdb_rated_movies.json`
- `_data/tmdb_recently_rated_movies.json`
- `assets/images/hardcover/*.webp`
- `assets/images/mal/*.webp`
- `assets/images/tmdb/movies/*.webp`

## Jekyll Configuration Highlights (`_config.yml`)

- Permalink: `/:slug`
- Plugins: `jekyll-sitemap`, `jekyll-archives` (year + tag archives)
- Timezone: `America/Los_Angeles`
- Excluded from build: `docs/`, `_data/most_recent_mastodon_post.yml`, `.rodney`

## Writing Posts

Posts live in `_posts/` as `YYYY-MM-DD-slug.md`. Supported front matter fields:

```yaml
---
title: "Post Title"
date: YYYY-MM-DD
tags: [tag1, tag2]
description: "Short description"
github: https://github.com/...   # optional — renders a GitHub button
---
```

Internal links to other posts use `.md` filenames (e.g., `[text](other-post.md)`); the `python.rb` plugin converts them at build time.

## Styling Notes

- SCSS is organized into per-concern files under `_sass/` and imported via `assets/css/main.scss`
- Responsive breakpoints have dedicated files: `_sass/ios.scss`, `_sass/android.scss`, `_sass/desktop.scss`
- Shared Hardcover book card styles are in `_sass/hardcover.scss` (used by both homepage and Books page)
- Books page overrides (smaller cards, line-clamped titles) are scoped under `.books-year-section` in `_sass/books.scss`

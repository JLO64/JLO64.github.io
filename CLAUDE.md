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

## Custom Plugins (`_plugins/`)

- **`hardcover_all_read.rb`** — Fetches all read books (status_id=3) from Hardcover's GraphQL API at build time. Downloads and converts cover images to WebP. Writes to `_data/hardcover_all_read.json`. Only overwrites the file on a successful API call — falls back to the committed file if the API is unavailable.
- **`hardcover_currently_reading.rb`** — Fetches currently-reading books (status_id=2) from Hardcover's GraphQL API at build time. Requires `HARDCOVER_TOKEN` (or `HARDCOVER_AUTHORIZATION`) env var. Downloads and converts cover images to WebP. Writes to `_data/hardcover_currently_reading.json`.
- **`mastodon_feed.rb`** — Fetches the latest Mastodon post from the RSS feed at `gotosocial.julianlopez.net`. Downloads and converts images to WebP. Writes to `_data/most_recent_mastodon_post.yml`.
- **`python.rb`** — Pre-processes post links: rewrites `[text](post-name.md)` → `[text]({% post_url post-name %})`.

## Environment Variables

Store in `.env` at the repo root (gitignored). The `.env` parser in `server_build_script.sh` handles JWT tokens with special characters.

| Variable | Purpose |
|---|---|
| `HARDCOVER_TOKEN` | Hardcover API auth token (JWT) |

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
| `_data/most_recent_mastodon_post.yml` | No | Regenerated each build |

**Important:** Jekyll loads `_data` files before running generator plugins. A plugin that writes to `_data` is always one build behind — the new data is used in the next build. This is why `hardcover_all_read.json` is committed: it's always present and up-to-date from the previous build.

## Auto-generated Files (do not edit manually)

- `_data/hardcover_currently_reading.json`
- `_data/most_recent_mastodon_post.yml`
- `assets/images/hardcover/*.webp`

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
- Theme (dark/light) toggle is handled by `_includes/toggle_theme_js.html`

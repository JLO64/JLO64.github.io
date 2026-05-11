#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable

# Function to get timestamp with decimal precision
get_timestamp() {
  perl -MTime::HiRes=time -e 'printf "%.2f", time'
}

# Set up logging
if [ -w "/home/julian/logs" ] || mkdir -p "/home/julian/logs/JLO64.github.io" 2>/dev/null; then
  LOG_DIR="/home/julian/logs/JLO64.github.io"
else
  LOG_DIR="./logs"
  mkdir -p "$LOG_DIR"
fi
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/build_${TIMESTAMP}.log"

# Redirect all output to log file (and still show in stdout)
exec > >(tee -a "$LOG_FILE") 2>&1

# Capture start time
START_TIME=$(get_timestamp)
echo "=== Build started at $(date) ==="

# parse arguments KEY=VALUE
while [ $# -gt 0 ]; do
  case "$1" in
  *=*)
    varname=$(echo "$1" | cut -d= -f1)
    varvalue=$(echo "$1" | cut -d= -f2-)
    eval "$varname=\"$varvalue\""
    ;;
  esac
  shift
done

# NGINX_DIR="/var/www/www" JEKYLL_DIR="/home/julian/jekyll_sites/JLO64.github.io" JEKYLL_BUILDER_IMAGE="blog_jekyll_builder" HARDCOVER_TOKEN="your_token_here"

if [ -z "${JEKYLL_DIR:-}" ]; then
  echo "JEKYLL_DIR is not set. Exiting."
  exit 1
fi
if [ -z "${NGINX_DIR:-}" ]; then
  echo "NGINX_DIR is not set. Exiting."
  exit 1
fi
if [ -z "${JEKYLL_BUILDER_IMAGE:-}" ]; then
  echo "JEKYLL_BUILDER_IMAGE is not set. Exiting."
  exit 1
fi

# Source .env so all API keys are available; takes precedence over any earlier KEY=VALUE args
if [ -f "$JEKYLL_DIR/.env" ]; then
  set -a
  . "$JEKYLL_DIR/.env"
  set +a
fi

if [ -z "${HARDCOVER_TOKEN:-}" ]; then
  echo "HARDCOVER_TOKEN is not set. Exiting."
  exit 1
fi

# Ensure PATH includes common binary locations
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Get the remote URL from the existing repo
REPO_URL=$(git -C "$JEKYLL_DIR" remote get-url origin)

# Clone into a temp directory and ensure cleanup on exit
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "Cloning $REPO_URL into $BUILD_DIR ..."
git clone "$REPO_URL" "$BUILD_DIR"

# Copy .env into the clone so plugins can find it if needed
if [ -f "$JEKYLL_DIR/.env" ]; then
  cp "$JEKYLL_DIR/.env" "$BUILD_DIR/.env"
fi

rm -rf "$NGINX_DIR"/*
docker run --rm -v "$BUILD_DIR":/srv/jekyll -e HARDCOVER_TOKEN="$HARDCOVER_TOKEN" -e TMDB_API_KEY="${TMDB_API_KEY:-}" -e MONKEYTYPE_API_KEY="${MONKEYTYPE_API_KEY:-}" -u "$(id -u):$(id -g)" "$JEKYLL_BUILDER_IMAGE" build
docker run --rm -v "$BUILD_DIR":/srv/jekyll -e HARDCOVER_TOKEN="$HARDCOVER_TOKEN" -e TMDB_API_KEY="${TMDB_API_KEY:-}" -e MONKEYTYPE_API_KEY="${MONKEYTYPE_API_KEY:-}" -u "$(id -u):$(id -g)" "$JEKYLL_BUILDER_IMAGE" build
cp -r "$BUILD_DIR"/_site/* "$NGINX_DIR"
chmod -R 755 "$NGINX_DIR"

# Calculate build duration
END_TIME=$(get_timestamp)
DURATION=$(perl -e "printf '%.2f', $END_TIME - $START_TIME")

echo ""
echo "=== Build completed at $(date) ==="
echo "=== Total build time: ${DURATION} seconds ==="

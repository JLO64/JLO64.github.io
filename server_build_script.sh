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

# add a check that exits if the variables are not set and exit with an error message
if [ -z "$JEKYLL_DIR" ]; then
  echo "JEKYLL_DIR is not set. Exiting."
  exit 1
fi
if [ -z "$NGINX_DIR" ]; then
  echo "NGINX_DIR is not set. Exiting."
  exit 1
fi
if [ -z "$JEKYLL_BUILDER_IMAGE" ]; then
  echo "JEKYLL_BUILDER_IMAGE is not set. Exiting."
  exit 1
fi
if [ -z "${HARDCOVER_TOKEN:-}" ]; then
  # Try to load from .env file if not provided as argument
  if [ -f "$JEKYLL_DIR/.env" ]; then
    set -a
    . "$JEKYLL_DIR/.env"
    set +a
  fi

  if [ -z "${HARDCOVER_TOKEN:-}" ]; then
    echo "HARDCOVER_TOKEN is not set and .env file not found. Exiting."
    exit 1
  fi
fi

# Ensure PATH includes common binary locations
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cd "$JEKYLL_DIR" || { echo "Failed to cd to $JEKYLL_DIR"; exit 1; }
git pull
git reset --hard HEAD
rm -rf "$NGINX_DIR"/*
docker run --rm -v "$JEKYLL_DIR":/srv/jekyll -e HARDCOVER_TOKEN="$HARDCOVER_TOKEN" -u "$(id -u):$(id -g)" "$JEKYLL_BUILDER_IMAGE" build
docker run --rm -v "$JEKYLL_DIR":/srv/jekyll -e HARDCOVER_TOKEN="$HARDCOVER_TOKEN" -u "$(id -u):$(id -g)" "$JEKYLL_BUILDER_IMAGE" build
cp -r "$JEKYLL_DIR"/_site/* "$NGINX_DIR"
chmod -R 755 "$NGINX_DIR"

# Calculate build duration
END_TIME=$(get_timestamp)
DURATION=$(perl -e "printf '%.2f', $END_TIME - $START_TIME")

echo ""
echo "=== Build completed at $(date) ==="
echo "=== Total build time: ${DURATION} seconds ==="

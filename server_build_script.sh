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
if [ -z "$HARDCOVER_TOKEN" ]; then
  # Try to load from .env file if not provided as argument
  if [ -f "$JEKYLL_DIR/.env" ]; then
    export $(grep -v '^#' "$JEKYLL_DIR/.env" | xargs)
  fi

  if [ -z "$HARDCOVER_TOKEN" ]; then
    echo "HARDCOVER_TOKEN is not set and .env file not found. Exiting."
    exit 1
  fi
fi

cd $JEKYLL_DIR
git reset --hard HEAD
git pull
rm -rf $NGINX_DIR/*
docker run --rm -v $JEKYLL_DIR:/srv/jekyll -e HARDCOVER_TOKEN="$HARDCOVER_TOKEN" -u $(id -u):$(id -g) $JEKYLL_BUILDER_IMAGE build
cp -r $JEKYLL_DIR/_site/* $NGINX_DIR
chmod -R 755 $NGINX_DIR


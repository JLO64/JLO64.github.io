rm -rf $NGINX_DIR/*
docker run --rm -v $JEKYLL_DIR:/srv/jekyll -u $(id -u):$(id -g) $JEKYLL_BUILDER_IMAGE build
cp -r $JEKYLL_DIR/_site/* $NGINX_DIR
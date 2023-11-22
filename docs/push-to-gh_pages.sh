#!/bin/bash

# Change the current working directory to the directory where the script is located
cd "$(dirname "$0")"

# Run the imagekit.py script
python3 imagekit.py

# Build the Jekyll site
echo "destination: docs" >> _config.yml
bundle exec jekyll build
sudo sed -i '/destination: docs/d' _config.yml

git add ./docs/
git commit -m "Updated website"
git push origin master

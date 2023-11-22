#!/bin/bash

# Change the current working directory to the directory where the script is located
cd "$(dirname "$0")"

# Run the imagekit.py script
python3 imagekit.py

# Build the Jekyll site
echo "destination: github_site" >> _config.yml
bundle exec jekyll build
sudo sed -i '/destination: github_site/d' _config.yml


git add --all
git commit -m "Updated site"
git push origin master

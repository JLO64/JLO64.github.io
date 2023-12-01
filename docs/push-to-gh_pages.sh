#!/bin/bash

# Change the current working directory to the directory where the script is located
cd "$(dirname "$0")"

# Run the imagekit.py script
# python3 imagekit.py

# Build the Jekyll site
echo -e "\ndestination: docs" >> _config.yml
bundle exec jekyll build
sudo sed -i '/destination: docs/d' _config.yml

python3 check-new-post.py

git add ./docs/
git commit -m "Updated website: $(date '+%Y-%m-%d %H:%M')"
git push origin master
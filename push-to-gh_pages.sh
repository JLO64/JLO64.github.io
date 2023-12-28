#!/bin/bash

# Change the current working directory to the directory where the script is located
cd "$(dirname "$0")"

# Run the imagekit.py script
# python3 imagekit.py
python3 gpt-summarize.py

# Build the Jekyll site
echo -e "destination: docs" >> _config.yml
bundle exec jekyll build
sed -i '/destination: docs/d' _config.yml

screen -d -m python3 check-new-post.py

sleep 10s

git add ./docs/
git commit -m "Updated website: $(date '+%Y-%m-%d %H:%M')"
git push origin master
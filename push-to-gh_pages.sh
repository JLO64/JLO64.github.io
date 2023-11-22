#!/bin/bash

# Change the current working directory to the directory where the script is located
cd "$(dirname "$0")"

# Run the imagekit.py script
python imagekit.py

# Build the Jekyll site
bundle exec jekyll build

# Push the contents of the _site folder to the github-pages branch
git subtree push --prefix _site origin github-pages

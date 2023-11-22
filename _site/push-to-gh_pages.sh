#!/bin/bash

# Change the current working directory to the directory where the script is located
cd "$(dirname "$0")"

# Run the imagekit.py script
python3 imagekit.py

# Build the Jekyll site
bundle exec jekyll build

# Push the contents of the _site folder to the github-pages branch, overwriting everything in the branch
git checkout gh-pages && git rm -r --cached --ignore-unmatch . && git add _site/ --force && git commit -m "Add contents of _site folder to gh-pages branch" && git push origin gh-pages


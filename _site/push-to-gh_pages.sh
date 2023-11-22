#!/bin/bash

# Change the current working directory to the directory where the script is located
cd "$(dirname "$0")"

echo -e \n Starting Photo Processing

# Run the imagekit.py script
python3 imagekit.py

echo -e \n Starting Jekyll site building

# Build the Jekyll site
bundle exec jekyll build

echo -e \n Pushing contents of _site to GitHub

# Push the contents of the _site folder to the github-pages branch, overwriting everything in the branch
git checkout gh-pages && git rm -r --cached --ignore-unmatch . && git add "_site/*" --force && git commit -m "Add contents of _site folder to gh-pages branch" && git push origin gh-pages







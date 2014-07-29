#!/bin/bash

git pull

echo "Updating Sub Repos"

if [ ! -d "./drupal" ]; then
  git clone --branch 8.0.x http://git.drupal.org/project/drupal.git drupal
else
  cd ./drupal
  git fetch --all
  cd ../
fi

if [ ! -d "./pages" ]; then
  git clone --branch gh-pages git@github.com:ericduran/drupalcores.git pages
else
  cd ./pages
  git pull
  cd ..
fi

./cores.rb > ./pages/index.html
./companies.rb > ./pages/companies.html
./json.rb > ./pages/data.json

cd pages
git commit -am "Update bump."
git push

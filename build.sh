#!/bin/bash

git pull

echo "Updating Sub Repos"

if [ ! -d "./drupal" ]; then
  git clone --branch 8.0.x http://git.drupal.org/project/drupal.git
else
  cd ./drupal
  git pull
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
./json.rb > ./pages/data.json

cd pages

#!/bin/bash

git pull

echo "Updating Sub Repos"

if [ ! -d "./app/drupalcore" ]; then
  git clone --branch 8.0.x http://git.drupal.org/project/drupal.git ./app/drupalcore
else
  cd ./app/drupalcore
  git pull
  cd ../bin
fi

./cores.rb > ../../dist/index.html
./json.rb > ../../dist/data.json

cd ../../dist

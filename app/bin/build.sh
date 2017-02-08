#!/bin/bash

git pull

echo "Updating Sub Repos"

if [ ! -d "./app/drupalcore" ]; then
  git clone --branch 8.4.x http://git.drupal.org/project/drupal.git ./app/drupalcore
else
  cd ./app/drupalcore
  git checkout 8.4.x
  git pull
  cd ../bin
fi

./cores.rb > ../../dist/next.html
./json.rb > ../../dist/next.json

cd ../../dist
mv next.html index.html
mv next.json index.json

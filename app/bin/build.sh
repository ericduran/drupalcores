#!/bin/bash

git pull

echo "Updating Sub Repos"

if [ ! -d "./app/drupalcore" ]; then
  git clone https://git.drupalcode.org/project/drupal.git ./app/drupalcore
else
  cd ./app/drupalcore
  git remote update
  git remote set-head origin -a
  git checkout origin/HEAD
  cd ../bin
fi

./cores.rb > ../../dist/next.html
./json.rb > ../../dist/next.json

cd ../../dist
mv next.html index.html
mv next.json index.json

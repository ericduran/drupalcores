#!/bin/bash

echo "Updating Sub Repos"

if [ ! -d "./drupal" ]; then
  git clone --branch 8.x http://git.drupal.org/project/drupal.git
fi

if [ ! -d "./pages" ]; then
  git clone --branch gh-pages git@github.com:ericduran/drupalcores.git pages
fi


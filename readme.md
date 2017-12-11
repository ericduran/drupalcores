[![Build Status](https://travis-ci.org/lauriii/drupalcores.svg?branch=master)](https://travis-ci.org/lauriii/drupalcores)
# DrupalCores
![count all the git commits](https://github.com/ericduran/drupalcores/raw/pystart/img.jpg)

Ruby script to parse all the git commit, aggregate every users commit count and generate
a flat html page for easy viewing for all the contributes and commit counts.

## Instructions
Install Ruby dependancies:

Make sure you have [Bundler](http://bundler.io/) installed.

    bundle install

Install node dependancies:

    npm install

Install gulp globally:

    npm install gulp -g

Install bower globally:

    npm install bower -g

Once you've done that you run:

    gulp

This might take a long time for the first parsing... (~1.5h)

To update contributor > company mapping info, run:

    gulp companyinfo

View online:
 [DrupalCores.com](http://www.drupalcores.com/)

Do you only want the data?
 [BAM!!!](http://www.drupalcores.com/data.json)

## FAQ

### My credits are split between two or more names.
[Name_mappings.yml](https://github.com/lauriii/drupalcores/blob/master/app/config/name_mappings.yml) is used to map incorrect names to the correct name. You can edit the file and submit a pull request.

## I've changed companies but my commit credits are still listed under my old company.
The contributor > company mappings are cached, which doesn't get updated automatically at the moment. It takes a long time to parse the data from drupal.org.


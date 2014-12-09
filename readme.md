# DrupalCores
![count all the git commits](https://github.com/ericduran/drupalcores/raw/pystart/img.jpg)

Ruby script to parse all the git commit, aggregate every users commit count and generate
a flat html page for easy viewing for all the contributes and commit counts.

## Instructions
First you need to clone a copy of the drupal 8 branch into your drupalcores directory

    git clone --branch 8.0.x http://git.drupal.org/project/drupal.git
    git clone --branch gh-pages git@github.com:lauriii/drupalcores.git app/pages

Once you have a git repo of drupal core in the drupal directory then you can run the cores.rb script

    ./cores.rb

For the company list do:

    ./app/bin/companies.rb > dist/companies.html

Takes a long time for the first parsing... (~1.5h)
After that it uses the company_mapping.yml and company_infos.yml.

The companies.rb accepts a parameter to either force a update of all people and companies (--update-all)
or to update people, which were not found (--update-not-found).

View online:
 [DrupalCores.com](http://www.drupalcores.com/)

Do you only want the data?
 [BAM!!!](http://www.drupalcores.com/data.json)

## FAQ

### My credits are split between two or more names.
[Name_mappings.yml](https://github.com/lauriii/drupalcores/blob/master/name_mappings.yml) is used to map incorrect names to the correct name. You can edit the file and submit a pull request.

## I've changed companies but my commit credits are still listed under my old company.
The contributor/company mappings are cached within [company_mapping.yml], which doesn't get updated automatically at the moment. It takes a long time to parse the data from drupal.org. You can update this yourself and submit a pull request by running the following command in the repo:

    ./app/bin/companies.rb --update-all > dist/companies.html


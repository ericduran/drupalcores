#!/usr/bin/env ruby
require 'erb'
require 'yaml'

name_mappings = YAML::load_file('./name_mappings.yml')
contributors = Hash.new(0)
%x[git --git-dir=drupal/.git --work-tree=drupal log 8.x --since=2011-03-09 -s --format=%s].split("\n").each do |m|
  m.scan(/\s(?:by\s?)([\w\s,.|]+):/i).each do |people|
    people[0].split(/[,|]/).each do |p|
      name = p.strip.downcase
      contributors[name_mappings[name] || name] += 1 unless p.nil?
    end
  end
end

sum = contributors.values.reduce(:+).to_f
contributors = Hash[contributors.sort_by {|k, v| v }.reverse]
puts ERB.new(DATA.readlines.join, 0, '>').result

__END__
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>DrupalCores</title>
  <meta name="description" content="A simple list of all contributes to Drupal 8 core">
  <meta name="author" content="Eric J. Duran">
  <link type="text/plain" rel="author" href="http://ericduran.github.com/drupalcores/humans.txt" />
  <link rel="stylesheet" type="text/css" media="screen" href="stylesheets/stylesheet.css">
</head>
<body>
    <div id="header_wrap" class="outer">
        <header class="inner">
          <a id="forkme_banner" href="https://github.com/ericduran/drupalcores">View on GitHub</a>
          <h1 id="project_title">DrupalCores</h1>
          <h2 id="project_tagline">A very basic table of all contributors to Drupal 8 Core</h2>
        </header>
    </div>

    <div id="main_content_wrap" class="outer">
      <section id="main_content" class="inner">
        <div class="table-filter">
          Total: <%= contributors.length %> contributors
        </div>

        <table cellpadding="4" style="border: 1px solid #000000; border-collapse: collapse;" border="1">
  <col width="70%">
  <col width="15%">
  <col width="15%">
 <tr>
  <th>Drupal.org Username</th>
  <th>Mentions</th>
  <th>Percent</th>
 </tr>
 <% contributors.each do |name, mentions| %>
 <tr>
  <td><%= name %></td>
  <td><%= mentions %></td>
  <td><%= ((mentions/sum)*100).round(4) %>%</td>
 </tr>
 <% end %>

</table>
      </section>
    </div>

    <div id="footer_wrap" class="outer">
      <footer class="inner">
        <p class="updated">Last updated <%= Time.new %></p>
        <p class="copyright">DrupalCores maintained by <a href="https://github.com/ericduran">"ericduran" <3 ruby, lol</a></p>
        <p>Published with <a href="http://pages.github.com">GitHub Pages</a></p>
      </footer>
    </div>
  </body>
</html>

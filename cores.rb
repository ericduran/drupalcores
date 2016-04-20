#!/usr/bin/env ruby

log_args = ARGV[0] || '--since=2011-03-09'
git_command = 'git --git-dir=drupal/.git --work-tree=drupal log 8.2.x ' + log_args + ' -s --format=%s'

Encoding.default_external = Encoding::UTF_8
require 'erb'
require 'yaml'

name_mappings = YAML::load_file('./name_mappings.yml')
contributors = Hash.new(0)
i = 1;
lastOrder = -1;
lastMentions = 0;
commits = Array.new
reverts = Array.new

%x[#{git_command}].split("\n").each do |c|
  if c.index('Revert') == 0 then
    reverts.push(c.scan(/#([0-9]+)/))
  else
    commits.push(c)
  end
end

commits.each_with_index do |c, i|
  if r = reverts.index{ |item| item == c.scan(/#([0-9]+)/) }
    commits.delete_at(i)
    reverts.delete_at(r)
  end
end

commits.each do |m|
  m.gsub(/\-/, '_').scan(/\s(?:by\s?)([[:word:]\s,.|]+):/i).each do |people|
    people[0].split(/(?:,|\||\band\b|\bet al(?:.)?)/).each do |p|
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
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
  <title>DrupalCores</title>
  <meta name="description" content="A simple list of all contributors to Drupal 8 core">
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
        <div id="chart_div" style="width: 640px; height: 400px;"></div>
        <div class="table-filter">
          Total: <%= contributors.length %> contributors
          <ul>
            <li><a href="index.html">List Contributors</a></li>
            <li><a href="companies.html">List Companies</a></li>
          </ul>
        </div>

        <table cellpadding="4" style="border: 1px solid #000000; border-collapse: collapse;" border="1">
  <col width="5%">
  <col width="65%">
  <col width="15%">
  <col width="15%">
 <tr>
 <th>#</th>
  <th>Drupal.org Username</th>
  <th>Mentions</th>
  <th>Percent</th>
 </tr>
 <% contributors.each do |name, mentions| %>
 <tr>
  <td id="<%= name %>"><%= (lastMentions == mentions) ? lastOrder : i %></td>
  <td><a href="https://www.drupal.org/u/<%= name.gsub ' ', '-' %>"><%= name %></a></td>
  <td><%= mentions %></td>
  <td><%= ((mentions/sum)*100).round(4) %>%</td>
  <% if lastMentions != mentions %>
    <% lastOrder = i %>
  <% end %>
  <% i += 1 %>
  <% lastMentions = mentions %></tr>
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


<script src="https://www.google.com/jsapi"></script>
<script>
  var chartData = [
   ['Task', 'Drupal core charts'],
   ['1 commit',<%= contributors.select {|k,v| v < 2}.length %>],
   ['2 - 10 commits',<%= contributors.select {|k,v| (v > 1 && v < 11) }.length %>],
   ['11 - 100 commits',<%= contributors.select {|k,v| (v > 10 && v < 101) }.length %>],
   ['Over 100 commits',<%= contributors.select {|k,v| v > 100}.length %>]
  ];
  google.load("visualization", "1", {packages:["corechart"]});
  google.setOnLoadCallback(drawChart);
  function drawChart() {
    var data = google.visualization.arrayToDataTable(chartData);

    var options = {
      title: 'Drupal Cores Contributors Chart',
      backgroundColor: '#f2f2f2'
    };

    var chart = new google.visualization.PieChart(document.getElementById('chart_div'));
    chart.draw(data, options);
  }

</script>

  </body>
</html>

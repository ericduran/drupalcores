#!/usr/bin/env ruby

Encoding.default_external = Encoding::UTF_8
require 'erb'
require 'yaml'

name_mappings = YAML::load_file('./name_mappings.yml')
contributors = Hash.new(0)
i = 0
%x[git --git-dir=drupal/.git --work-tree=drupal log 8.x --since=2011-03-09 -s --format=%s].split("\n").each do |m|
  m.gsub(/\-/, '_').scan(/\s(?:by\s?)([[:word:]\s,.|]+):/i).each do |people|
    people[0].split(/(?:,|\||\band\b)/).each do |p|
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
          <span>Total: <%= contributors.length %> contributors</span>
          <label for="datatable-filter">Searchy:</label>
          <input name="datatable-filter" id="datatable-filter" />
        </div>

        <table id="commit-table" cellpadding="4" style="border: 1px solid #000000; border-collapse: collapse;" border="1">
  <col width="5%">
  <col width="65%">
  <col width="15%">
  <col width="15%">
  <thead>
   <tr>
    <th>#</th>
    <th>Drupal.org Username</th>
    <th>Mentions</th>
    <th>Percent</th>
   </tr>
 </thead>
 <tbody>
 <% contributors.each do |name, mentions| %>
 <tr>
  <td id="<%= name %>"><%= i+=1 %></td>
  <td><%= name %></td>
  <td><%= mentions %></td>
  <td><%= ((mentions/sum)*100).round(4) %>%</td>
 </tr>
 <% end %>
 </tbody>
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
   ['Over 10 commits',<%= contributors.select {|k,v| v > 10}.length %>]
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

<script src="http://ajax.aspnetcdn.com/ajax/jquery/jquery-1.9.0.js"></script>
<script src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.min.js"></script>
<script>
  $(document).ready(function () {
    $('#commit-table').dataTable({
        bPaginate: false,
        // Manually attach to an input field, so we can control its position.
        sDom: 'lrtip',
        fnInitComplete: function () {
            var that = this;
            $('#datatable-filter').on('keydown', function () {
                that.fnFilter($(this).val());
            });
        }
    });
  });
</script>
  </body>
</html>

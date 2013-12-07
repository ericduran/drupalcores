#!/usr/bin/env ruby

Encoding.default_external = Encoding::UTF_8
require 'erb'
require 'yaml'
require 'nokogiri'
require 'open_uri_redirections'

name_mappings = YAML::load_file('./name_mappings.yml')
contributors = Hash.new(0)
i = 1;
lastOrder = -1;
lastMentions = 0;
%x[git --git-dir=drupal/.git --work-tree=drupal log 8.x --since=2011-03-09 -s --format=%s].split("\n").each do |m|
  m.gsub(/\-/, '_').scan(/\s(?:by\s?)([[:word:]\s,.|]+):/i).each do |people|
    people[0].split(/(?:,|\||\band\b|\bet al(?:.)?)/).each do |p|
      name = p.strip.downcase
      contributors[name_mappings[name] || name] += 1 unless p.nil?
    end
  end
end

companies = Hash.new(0)
count = 0
contributors.each do |name,mentions|
  url = "http://dgo.to/@#{name}"
  url = URI::encode(url)
#  puts "#{name} has #{commits} commits with #{url} (#{i}/#{contributors.length})"
  html = open(url, :allow_redirections => :safe)
  doc = Nokogiri::HTML(html)
  found = true
  doc.css('title').each do |title|
    if title.text == 'Users | Drupal.org'
      found = false
      unless companies.key? 'not_found'
        companies['not_found'] = Hash.new(0)
        companies['not_found']['title'] = 'Users not found'
        companies['not_found']['link'] = 'Users not found'
        companies['not_found']['contributors'] = Hash.new(0)
      end
      companies['not_found']['mentions'] += mentions
      companies['not_found']['contributors'][name] = mentions
    end
  end
  if found
    doc.css('dt').each do |dt|
      if dt.content == 'Current company or organization'
        link = dt.next_element.child
        if link.at_css('img')
          company = link.at_css('img')['title']
        else
          company = link.child.text
        end
        company = company.strip
        unless companies.key? company
          link['href'] = 'https://drupal.org' + link['href']
          companies[company] = Hash.new(0)
          companies[company]['title'] = company
          companies[company]['link'] = link.to_s
          companies[company]['contributors'] = Hash.new(0)
        end
        companies[company]['mentions'] += mentions
        companies[company]['contributors'][name] = mentions
      end
    end
  end
  count += 1
#  if count > 5
#    break
#  end
end

companies = companies.sort_by {|k, v| v['mentions'] }.reverse

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
          Total: <%= companies.length %> contributors
        </div>

        <table cellpadding="4" style="border: 1px solid #000000; border-collapse: collapse;" border="1">
  <col width="5%">
  <col width="65%">
  <col width="15%">
  <col width="15%">
 <tr>
 <th>#</th>
  <th>Company</th>
  <th>Mentions</th>
  <th>Percent</th>
 </tr>
 <% companies.each do |name, values| %>
 <tr>
  <td id="<%= name %>"><%= (lastMentions == values['mentions']) ? lastOrder : i %></td>
  <td><%= values['link'] %> (<%= values['contributors'].length %> - <%= values['contributors'].map{|k,v| "#{k} [#{v}]"}.join(', ') %>) </td>
  <td><%= values['mentions'] %></td>
  <td><%= ((values['mentions']/sum)*100).round(4) %>%</td>
  <% if lastMentions != values['mentions'] %>
    <% lastOrder = i %>
  <% end %>
  <% i += 1 %>
  <% lastMentions = values['mentions'] %></tr>
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
   ['1 commit',<%= companies.select {|k,v| v['mentions'] < 2}.length %>],
   ['2 - 10 commits',<%= companies.select {|k,v| (v['mentions'] > 1 && v['mentions'] < 11) }.length %>],
   ['Over 10 commits',<%= companies.select {|k,v| v['mentions'] > 10}.length %>]
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

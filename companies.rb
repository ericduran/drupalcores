#!/usr/bin/env ruby

Encoding.default_external = Encoding::UTF_8
require 'erb'
require 'yaml'
require 'nokogiri'
require 'open_uri_redirections'

COMPANY_NOT_FOUND='not_found'
COMPANY_NOT_DEFINED='not_defined'
UPDATE_NONE=0
UPDATE_NOT_FOUND=1
UPDATE_ALL=1

name_mappings = YAML::load_file('./name_mappings.yml')
$companies_info = YAML::load_file('./company_infos.yml') || Hash.new(0)
company_mapping = YAML::load_file('./company_mapping.yml') || Hash.new(0)
contributors = Hash.new(0)
name_variants = Hash.new(0)
update=UPDATE_NONE
if ARGV.length == 1
  if ARGV[0] == '--update-all'
    update=UPDATE_ALL
  else
    if ARGV[0] == '--update-not-found'
      update=UPDATE_NOT_FOUND
    end
  end
end

i = 1;
lastOrder = -1;
lastMentions = 0;
%x[git --git-dir=drupal/.git --work-tree=drupal log 8.x --since=2011-03-09 -s --format=%s].split("\n").each do |m|
  m.scan(/\s(?:by\s?)([[:word:]\s,.|]+):/i).each do |people|
    people[0].split(/(?:,|\||\band\b|\bet al(?:.)?)/).each do |p|
      name = p.gsub(/\-/, '_').strip.downcase
      name_variants[name] = p.strip unless p.strip == name
      contributors[name_mappings[name] || name] += 1 unless p.nil?
    end
  end
end

companies = Hash.new(0)

def ensure_company(companies, key, title, link)
  unless companies.key? key
    companies[key] = Hash.new(0)
    companies[key]['contributors'] = Hash.new(0)
    if $companies_info.key? key
      companies[key]['title'] = $companies_info[key]['title']
      companies[key]['link'] = $companies_info[key]['link']
    else
      companies[key]['title'] = title
      companies[key]['link'] = link
    end
  end
end

contributors.sort_by {|k, v| v }.reverse.each do |name,mentions|
  if company_mapping.key? name
    if update == UPDATE_NONE or (update == UPDATE_NOT_FOUND and company_mapping[name] != COMPANY_NOT_FOUND)
      ensure_company(companies, company_mapping[name], 'should be filled via company infos', 'should be filled via company infos')
      companies[company_mapping[name]]['mentions'] += mentions
      companies[company_mapping[name]]['contributors'][name] = mentions
      next
    end
  end
  if name_variants.key? name
    url = "http://dgo.to/@#{name_variants[name]}"
  else
    url = "http://dgo.to/@#{name}"
  end
  url = URI::encode(url)
  begin
    html = open(url, :allow_redirections => :safe)
    doc = Nokogiri::HTML(html)
  rescue
    next
  end
  found = true
  doc.css('title').each do |title|
    if title.text == 'Users | Drupal.org'
      found = false
      results = doc.css('ol.user-results li h3 a')
      # If we only have one results, its found ;)
      if results.length == 1
        begin
          html = open(results.first['href'], :allow_redirections => :safe)
          doc = Nokogiri::HTML(html)
          found = true
        rescue
          found = false
        end
      end
      unless found
        ensure_company(companies, COMPANY_NOT_FOUND, 'Users not found', 'Users not found')
        companies[COMPANY_NOT_FOUND]['mentions'] += mentions
        companies[COMPANY_NOT_FOUND]['contributors'][name] = mentions
      end
    end
  end
  if found
    found = false
    doc.css('dt').each do |dt|
      if dt.content == 'Current company or organization'
        link = dt.next_element.child
        if link.at_css('img')
          company = link.at_css('img')['title']
        else
          company = link.child.text
        end
        company = company.strip
        company_key = company.downcase
        link['href'] = 'https://drupal.org' + link['href']
        ensure_company(companies, company_key, company, link.to_s)
        companies[company_key]['mentions'] += mentions
        companies[company_key]['contributors'][name] = mentions
        found = true
      end
    end
    unless found
      ensure_company(companies, COMPANY_NOT_DEFINED, 'Not specified', 'Not specified')
      companies[COMPANY_NOT_DEFINED]['mentions'] += mentions
      companies[COMPANY_NOT_DEFINED]['contributors'][name] = mentions
    end
  end
end

companies = companies.sort_by {|k, v| v['mentions'] }.reverse
companies.each do |k, values|
  unless $companies_info.key? k
    $companies_info[k] = Hash.new(0)
    $companies_info[k]['title'] = values['title']
    $companies_info[k]['link'] = values['link']
  end
  values['contributors'].each do |name, mentions|
    company_mapping[name] = k
  end
  if values['contributors'].length == 0
    $companies_info.delete(k)
  end
end
File.open('./company_infos.yml', 'w') { |f| YAML.dump($companies_info, f) }
File.open('./company_mapping.yml', 'w') { |f| YAML.dump(company_mapping, f) }

sum = contributors.values.reduce(:+).to_f
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
          <h2 id="project_tagline">A very basic table of all companies with contributors to Drupal 8 Core</h2>
        </header>
    </div>

    <div id="main_content_wrap" class="outer">
      <section id="main_content" class="inner">
        <div id="chart_div" style="width: 640px; height: 400px;"></div>
        <div class="table-filter">
          <ul>
          <li>The exposed data takes only into account the company that the contributor listed on his
          drupal.org profile at the time this list has been curated, so it does not represent that the
          company listed is the company that could have sponsored his contribution.</li>
          <li>This list only reflects commit mentions by individuals. Not every commit mention is a valuable
          as others. Is just a metric, so be careful when interpreting it.</li>
          <li>There are plenty of other ways of contribution to the Drupal community as an individual or
          organization. Please check <a href="https://drupal.org/contribute">https://drupal.org/contribute</a>
          for ways of getting involved.</li>
          </ul>
          Total: <%= companies.length %> companies listed
          <ul>
            <li><a href="index.html">List Contributors</a></li>
            <li><a href="companies.html">List Companies</a></li>
          </ul>
        </div>

        <table cellpadding="4" style="border: 1px solid #000000; border-collapse: collapse;" border="1" class="companies">
  <col width="5%">
  <col width="50%">
  <col width="15%">
  <col width="15%">
  <col width="15%">
 <tr>
 <th>#</th>
  <th>Company</th>
  <th>Contributors</th>
  <th>Mentions</th>
  <th>Percent</th>
 </tr>
 <% companies.each do |name, values| %>
 <tr>
  <td id="<%= name %>"><%= (lastMentions == values['mentions']) ? lastOrder : i %></td>
  <td><%= values['link'] %> <img src="images/icon_info.png" alt="Info" title="Toggle employees" class="toggle"><div class="employees" style="display: none"><%= values['contributors'].map{|k,v| "<a href=\"http://dgo.to/@#{k}\">#{k}</a> [#{v}]"}.join(', ') %></div></td>
  <td><%= values['contributors'].length %></td>
  <td><%= values['mentions'] %> (~<%= values['mentions'] / values['contributors'].length %>)</td>
  <td><%= ((values['mentions']/sum)*100).round(4) %>%</td>
  <% if lastMentions != values['mentions'] %>
    <% lastOrder = i %>
  <% end %>
  <% i += 1 %>
  <% lastMentions = values['mentions'] %>
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
<script src="js/libs/jquery-1.7.1.min.js"></script>
<script>
  $('table.companies tr td .toggle').click(function() {
    $(this).parent().find('.employees').toggle();
  });
</script>
  </body>
</html>

#!/usr/bin/env ruby

Encoding.default_external = Encoding::UTF_8
require 'erb'
require 'yaml'
require 'open_uri_redirections'
require 'time'
require 'net/http'
require 'json'

COMPANY_NOT_FOUND='not_found'
COMPANY_NOT_DEFINED='not_defined'
COMPANY_NOT_SPECIFIED='Not specified'
UPDATE_NONE=0
UPDATE_NOT_FOUND=1
UPDATE_ALL=2

country_names = YAML::load_file('../config/country_names.yml')
name_variants = Hash.new(0)
Dir.mkdir('../data') unless Dir.exist?('../data')
if File.exists? ('../data/country_infos.yml')
  companies_info = YAML::load_file('../data/country_infos.yml')
else
  companies_info = Hash.new(0)
end
if File.exists? ('../data/country_mapping.yml')
  company_mapping = YAML::load_file('../data/country_mapping.yml') || Hash.new(0)
else
  company_mapping = Hash.new(0)
end
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
file = file = File.read('../../tmp/data.json')
data = JSON.parse(file)
contributors = data['contributors']
companies = Hash.new(0)

def ensure_company(companies, companies_info, key, title)
  unless companies.key? key
    companies[key] = Hash.new(0)
    companies[key]['contributors'] = Hash.new(0)
    if companies_info.key? key
      companies[key]['title'] = companies_info[key]['title']
    else
      companies[key]['title'] = title
    end
  end
end

contributors.sort_by {|k, v| v }.reverse.each do |name,mentions|
  next if name == COMPANY_NOT_SPECIFIED

  if company_mapping.key? name
    if update == UPDATE_NONE or (update == UPDATE_NOT_FOUND and company_mapping[name] != COMPANY_NOT_FOUND)
      ensure_company(companies, companies_info, company_mapping[name], country_names[company_mapping[name].upcase])
      companies[company_mapping[name]]['mentions'] += mentions
      companies[company_mapping[name]]['contributors'][name] = mentions
      next
    end
  end
  if name_variants.key? name
    urlname = name_variants[name]
  else
    urlname = name
  end
  url = URI::encode("https://www.drupal.org/api-d7/user.json?name=#{urlname}")
  uri = URI(url)
  begin
    response = Net::HTTP.get(uri)
    user = JSON.parse(response)
  rescue
    next
  end
  found = false
  if user['list'].count > 0
    found = true
  end
  unless found
    ensure_company(companies, companies_info, COMPANY_NOT_FOUND, 'Users not found')
    companies[COMPANY_NOT_FOUND]['mentions'] += mentions
    companies[COMPANY_NOT_FOUND]['contributors'][name] = mentions
  else
    company = user['list'][0]['field_country']
    if company.nil?
      company = COMPANY_NOT_SPECIFIED
      title = company
    else
      title = country_names[company]
    end
    company_key = company.downcase
    ensure_company(companies, companies_info, company_key, title)
    companies[company_key]['mentions'] += mentions
    companies[company_key]['contributors'][name] = mentions
  end
end

companies = companies.sort_by {|k, v| v['mentions'] }.reverse
companies.each do |k, values|
  unless companies_info.key? k
    companies_info[k] = Hash.new(0)
    companies_info[k]['title'] = values['title']
  end
  values['contributors'].each do |name, mentions|
    company_mapping[name] = k
  end
  if values['contributors'].length == 0
    companies_info.delete(k)
  end
end
File.open('../data/country_infos.yml', 'w') { |f| YAML.dump(companies_info, f) }
File.open('../data/country_mapping.yml', 'w') { |f| YAML.dump(company_mapping, f) }

sum = contributors.values.reduce(:+).to_f
puts ERB.new(DATA.readlines.join, 0, '>').result

time = Time.now()
description = "A simple table of all contributors to Drupal 8 core"
header = ERB.new(File.new("../templates/partials/header.html.erb").read).result(binding)
footer = ERB.new(File.new("../templates/partials/footer.html.erb").read).result(binding)
companies_template = File.open("../templates/countries.html.erb", 'r').read
renderer = ERB.new(companies_template)
puts output = renderer.result()

__END__

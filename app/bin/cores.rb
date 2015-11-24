#!/usr/bin/env ruby

Encoding.default_external = Encoding::UTF_8
require 'erb'
require 'yaml'
require 'time'
require 'json'

i = 1;
lastOrder = -1;
lastMentions = 0;

file = file = File.read('../../tmp/data.json')
data = JSON.parse(file)
contributors = data['contributors']
sum = contributors.values.reduce(:+).to_f
puts ERB.new(DATA.readlines.join, 0, '>').result

time = Time.now()
description = "A very basic table of all contributors to Drupal 8 Core"
header = ERB.new(File.new("../templates/partials/header.html.erb").read).result(binding)
footer = ERB.new(File.new("../templates/partials/footer.html.erb").read).result(binding)
index_template = File.open("../templates/index.html.erb", 'r').read
renderer = ERB.new(index_template)
puts output = renderer.result()

__END__

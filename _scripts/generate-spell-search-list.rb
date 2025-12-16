#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates a list of missing spell IDs with WoWHead search URLs
# Usage: ruby _scripts/generate-spell-search-list.rb

require 'yaml'
require 'uri'

KEYBINDS_FILE = '_data/keybinds.yml'
OUTPUT_FILE = 'spell_ids_to_find.md'

def load_keybinds
  YAML.load_file(KEYBINDS_FILE)
rescue Errno::ENOENT
  puts "Error: #{KEYBINDS_FILE} not found"
  exit 1
end

def find_missing_ids(keybinds_data)
  missing = []
  
  keybinds_data['classes'].each do |class_key, class_data|
    next unless class_data['abilities']
    
    class_data['abilities'].each do |key_id, ability|
      if ability.is_a?(Hash) && (ability['wowhead_id'].nil? || ability['wowhead_id'] == 'null' || ability['wowhead_id'] == '')
        missing << {
          'class' => class_key,
          'class_name' => class_data['name'],
          'key' => key_id,
          'ability_name' => ability['name'],
          'keybind' => ability['keybind']
        }
      end
    end
  end
  
  missing
end

def generate_search_url(ability_name)
  clean_name = ability_name.split(' / ').first.split(' (alt)').first.strip
  "https://www.wowhead.com/search?q=#{URI.encode_www_form_component(clean_name)}"
end

def main
  keybinds_data = load_keybinds
  missing = find_missing_ids(keybinds_data)
  
  if missing.empty?
    puts "No missing spell IDs found!"
    return
  end
  
  puts "Generating search list for #{missing.length} abilities..."
  
  output = []
  output << "# Missing Spell IDs Search List"
  output << ""
  output << "Total missing: #{missing.length}"
  output << ""
  output << "## Instructions"
  output << "1. Click each WoWHead link to find the spell"
  output << "2. The spell ID is in the URL: `https://www.wowhead.com/spell=12345` (12345 is the ID)"
  output << "3. Use `ruby _scripts/update-ids.rb [class] [key] [spell_id]` to add each ID"
  output << "   Example: `ruby _scripts/update-ids.rb warrior e 6572`"
  output << ""
  output << "---"
  output << ""
  
  # Group by class
  by_class = missing.group_by { |item| item['class_name'] }
  
  by_class.each do |class_name, items|
    output << "## #{class_name}"
    output << ""
    
    items.each do |item|
      search_url = generate_search_url(item['ability_name'])
      output << "- **#{item['keybind']}**: #{item['ability_name']}"
      output << "  - [WoWHead Search](#{search_url})"
      output << "  - Command: `ruby _scripts/update-ids.rb #{item['class']} #{item['key']} [ID]`"
      output << ""
    end
  end
  
  File.write(OUTPUT_FILE, output.join("\n"))
  puts "Generated: #{OUTPUT_FILE}"
  puts "Open this file to see all the search links and update commands."
end

main if __FILE__ == $PROGRAM_NAME


#!/usr/bin/env ruby
# frozen_string_literal: true

# Batch script to find spell IDs for all missing abilities
# Uses web search to find WoWHead spell pages and extracts IDs
# Usage: ruby _scripts/batch-find-ids.rb

require 'yaml'
require 'net/http'
require 'uri'
require 'cgi'

KEYBINDS_FILE = '_data/keybinds.yml'

def load_keybinds
  YAML.load_file(KEYBINDS_FILE)
rescue Errno::ENOENT
  puts "Error: #{KEYBINDS_FILE} not found"
  exit 1
end

def save_keybinds(keybinds_data)
  File.write(KEYBINDS_FILE, keybinds_data.to_yaml)
end

def search_wowhead_for_spell(spell_name)
  # Clean up spell name
  clean_name = spell_name.split(' / ').first.split(' (alt)').first.strip
  
  # Try searching WoWHead
  uri = URI("https://www.wowhead.com/search?q=#{CGI.escape(clean_name)}")
  
  begin
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    
    response = http.request(request)
    
    if response.code == '200'
      # Look for spell links in the HTML
      spell_ids = response.body.scan(/\/spell=(\d+)/).flatten.uniq
      return spell_ids.first.to_i if spell_ids.any?
    end
  rescue => e
    puts "  Error: #{e.message}"
  end
  
  nil
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

def main
  puts "Batch Spell ID Finder"
  puts "=" * 60
  puts "This script will search for spell IDs and update keybinds.yml"
  puts "You can review and confirm each update.\n\n"
  
  keybinds_data = load_keybinds
  missing = find_missing_ids(keybinds_data)
  
  if missing.empty?
    puts "No missing spell IDs found!"
    return
  end
  
  puts "Found #{missing.length} abilities without spell IDs\n\n"
  
  updated_count = 0
  skipped_count = 0
  
  missing.each_with_index do |item, index|
    puts "[#{index + 1}/#{missing.length}] #{item['class_name']} - #{item['keybind']}: #{item['ability_name']}"
    
    spell_id = search_wowhead_for_spell(item['ability_name'])
    
    if spell_id
      puts "  Found ID: #{spell_id}"
      print "  Update? (y/n/skip): "
      response = STDIN.gets.chomp.downcase
      
      if response == 'y' || response == 'yes'
        keybinds_data['classes'][item['class']]['abilities'][item['key']]['wowhead_id'] = spell_id
        updated_count += 1
        puts "  ✓ Updated!"
      elsif response == 'skip'
        skipped_count += 1
        puts "  ⊘ Skipped"
      else
        puts "  ✗ Not updated"
      end
    else
      puts "  ✗ Could not find spell ID"
    end
    
    puts
    sleep(0.5) # Rate limiting
  end
  
  if updated_count > 0
    print "\nSave #{updated_count} changes to #{KEYBINDS_FILE}? (y/n): "
    response = STDIN.gets.chomp.downcase
    
    if response == 'y' || response == 'yes'
      save_keybinds(keybinds_data)
      puts "Changes saved!"
      puts "\nNext steps:"
      puts "1. Run: ruby _scripts/fetch-abilities-blizzard.rb"
      puts "2. Run: ruby _scripts/preprocess-abilities.rb"
      puts "3. Rebuild Jekyll site"
    else
      puts "Changes discarded."
    end
  else
    puts "\nNo updates made."
  end
  
  puts "\nSummary:"
  puts "  Updated: #{updated_count}"
  puts "  Skipped: #{skipped_count}"
  puts "  Failed: #{missing.length - updated_count - skipped_count}"
end

main if __FILE__ == $PROGRAM_NAME


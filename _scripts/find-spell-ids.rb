#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to find WoWHead spell IDs by searching for ability names
# Usage: ruby _scripts/find-spell-ids.rb [ability_name]
#        ruby _scripts/find-spell-ids.rb --all  (finds all missing IDs)

require 'yaml'
require 'json'
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

def search_wowhead_spell(spell_name)
  # WoWHead search API
  # Note: WoWHead doesn't have a public search API, so we'll use their website search
  # and try to extract spell IDs from the results
  
  # Clean up spell name - remove " / " alternatives and extra info
  clean_name = spell_name.split(' / ').first.split(' (alt)').first.strip
  
  # Try direct spell page lookup via their data API
  # WoWHead uses a different approach - we can try the spell name in URL format
  search_term = clean_name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
  
  puts "  Searching for: #{clean_name}"
  puts "  Search term: #{search_term}"
  
  # Try to fetch from WoWHead's data API
  # Format: https://www.wowhead.com/spell=ID or search results
  uri = URI("https://www.wowhead.com/search?q=#{CGI.escape(clean_name)}")
  
  begin
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    
    response = http.request(request)
    
    if response.code == '200'
      # Parse HTML to find spell links
      # WoWHead search results contain links like /spell=12345
      spell_links = response.body.scan(/\/spell=(\d+)/).flatten.uniq
      
      if spell_links.any?
        puts "  Found #{spell_links.length} potential spell ID(s): #{spell_links.first(5).join(', ')}"
        return spell_links.first.to_i
      else
        puts "  No spell IDs found in search results"
        return nil
      end
    else
      puts "  Search failed (HTTP #{response.code})"
      return nil
    end
  rescue => e
    puts "  Error searching: #{e.message}"
    return nil
  end
end

def find_missing_ids(keybinds_data)
  missing = []
  
  keybinds_data['classes'].each do |class_key, class_data|
    next unless class_data['abilities']
    
    class_data['abilities'].each do |key_id, ability|
      if ability.is_a?(Hash) && (ability['wowhead_id'].nil? || ability['wowhead_id'] == 'null')
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

def update_keybind_with_id(keybinds_data, class_key, key_id, spell_id)
  if keybinds_data['classes'][class_key] &&
     keybinds_data['classes'][class_key]['abilities'] &&
     keybinds_data['classes'][class_key]['abilities'][key_id]
    keybinds_data['classes'][class_key]['abilities'][key_id]['wowhead_id'] = spell_id
    return true
  end
  false
end

def save_keybinds(keybinds_data)
  File.write(KEYBINDS_FILE, keybinds_data.to_yaml)
end

def interactive_mode
  puts "Interactive Spell ID Finder"
  puts "=" * 50
  puts "Enter ability names to search for spell IDs."
  puts "Type 'quit' to exit.\n\n"
  
  loop do
    print "Ability name: "
    input = STDIN.gets.chomp
    
    break if input.downcase == 'quit' || input.downcase == 'exit'
    next if input.empty?
    
    spell_id = search_wowhead_spell(input)
    if spell_id
      puts "  -> Spell ID: #{spell_id}"
      puts "  -> WoWHead URL: https://www.wowhead.com/spell=#{spell_id}\n\n"
    else
      puts "  -> Could not find spell ID. Try searching manually on WoWHead.\n\n"
    end
  end
end

def find_all_mode
  puts "Finding all missing spell IDs..."
  puts "=" * 50
  
  keybinds_data = load_keybinds
  missing = find_missing_ids(keybinds_data)
  
  if missing.empty?
    puts "No missing spell IDs found!"
    return
  end
  
  puts "Found #{missing.length} abilities without spell IDs:\n\n"
  
  missing.each_with_index do |item, index|
    puts "[#{index + 1}/#{missing.length}] #{item['class_name']} - #{item['keybind']}: #{item['ability_name']}"
    spell_id = search_wowhead_spell(item['ability_name'])
    
    if spell_id
      print "  Found ID: #{spell_id}. Update? (y/n): "
      response = STDIN.gets.chomp.downcase
      
      if response == 'y' || response == 'yes'
        if update_keybind_with_id(keybinds_data, item['class'], item['key'], spell_id)
          puts "  ✓ Updated!"
        else
          puts "  ✗ Failed to update"
        end
      end
    else
      puts "  ✗ Could not find spell ID"
    end
    
    puts
    sleep(1) # Rate limiting
  end
  
  print "\nSave changes to #{KEYBINDS_FILE}? (y/n): "
  response = STDIN.gets.chomp.downcase
  
  if response == 'y' || response == 'yes'
    save_keybinds(keybinds_data)
    puts "Changes saved!"
  else
    puts "Changes discarded."
  end
end

def single_search_mode(ability_name)
  puts "Searching for: #{ability_name}"
  puts "=" * 50
  
  spell_id = search_wowhead_spell(ability_name)
  
  if spell_id
    puts "\nSpell ID: #{spell_id}"
    puts "WoWHead URL: https://www.wowhead.com/spell=#{spell_id}"
  else
    puts "\nCould not find spell ID. Try searching manually on WoWHead."
  end
end

def main
  if ARGV.empty?
    interactive_mode
  elsif ARGV[0] == '--all' || ARGV[0] == '-a'
    find_all_mode
  else
    single_search_mode(ARGV.join(' '))
  end
end

main if __FILE__ == $PROGRAM_NAME


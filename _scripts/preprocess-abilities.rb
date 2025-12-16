#!/usr/bin/env ruby
# frozen_string_literal: true

# Pre-build script to merge ability cache data into keybinds.yml
# This embeds the cached data directly into the keybinds file
# Run this before building Jekyll: ruby _scripts/preprocess-abilities.rb

require 'yaml'

KEYBINDS_FILE = '_data/keybinds.yml'
CACHE_FILE = '_data/abilities_cache.yml'
OUTPUT_FILE = '_data/keybinds.yml'

def load_yaml(file)
  YAML.load_file(file)
rescue => e
  puts "Error loading #{file}: #{e.message}"
  {}
end

def save_yaml(data, file)
  File.write(file, data.to_yaml)
end

def merge_cache_into_keybinds(keybinds, cache)
  return keybinds unless keybinds['classes'] && cache
  
  keybinds['classes'].each do |_class_key, class_data|
    next unless class_data['abilities']
    
    class_data['abilities'].each do |_key_id, ability|
      next unless ability.is_a?(Hash) && ability['wowhead_id']
      
      spell_id = ability['wowhead_id'].to_s
      # Try both string and integer keys
      cached = cache[spell_id] || cache[spell_id.to_i]
      
      if cached
        # Merge cached data into ability
        ability['icon'] = cached['icon']
        ability['tooltip'] = cached['tooltip']
        ability['cached_name'] = cached['name']
      end
    end
  end
  
  keybinds
end

def main
  puts "Preprocessing abilities..."
  puts "Loading keybinds from #{KEYBINDS_FILE}..."
  keybinds = load_yaml(KEYBINDS_FILE)
  
  puts "Loading cache from #{CACHE_FILE}..."
  cache = load_yaml(CACHE_FILE)
  
  if cache.empty?
    puts "Warning: Cache is empty. Run fetch-abilities-blizzard.rb first."
  else
    puts "Found #{cache.keys.length} cached abilities"
  end
  
  puts "Merging cache into keybinds..."
  merged = merge_cache_into_keybinds(keybinds, cache)
  
  puts "Saving to #{OUTPUT_FILE}..."
  save_yaml(merged, OUTPUT_FILE)
  
  puts "Done! Ability data is now embedded in keybinds.yml"
  puts "You can now build Jekyll and the icons will appear."
end

main if __FILE__ == $PROGRAM_NAME


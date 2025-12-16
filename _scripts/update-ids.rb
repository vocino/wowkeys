#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to manually update spell IDs in keybinds.yml
# Usage: ruby _scripts/update-ids.rb [class] [key] [spell_id]
# Example: ruby _scripts/update-ids.rb warrior q 23922

require 'yaml'

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

def update_id(class_key, key_id, spell_id)
  keybinds_data = load_keybinds
  
  unless keybinds_data['classes'][class_key]
    puts "Error: Class '#{class_key}' not found"
    puts "Available classes: #{keybinds_data['classes'].keys.join(', ')}"
    return false
  end
  
  unless keybinds_data['classes'][class_key]['abilities'][key_id]
    puts "Error: Key '#{key_id}' not found for class '#{class_key}'"
    return false
  end
  
  old_id = keybinds_data['classes'][class_key]['abilities'][key_id]['wowhead_id']
  keybinds_data['classes'][class_key]['abilities'][key_id]['wowhead_id'] = spell_id.to_i
  
  ability_name = keybinds_data['classes'][class_key]['abilities'][key_id]['name']
  class_name = keybinds_data['classes'][class_key]['name']
  
  puts "Updated: #{class_name} - #{key_id.upcase} (#{ability_name})"
  puts "  Old ID: #{old_id || 'null'}"
  puts "  New ID: #{spell_id}"
  
  save_keybinds(keybinds_data)
  puts "Changes saved to #{KEYBINDS_FILE}"
  true
end

def list_missing
  keybinds_data = load_keybinds
  missing = []
  
  keybinds_data['classes'].each do |class_key, class_data|
    next unless class_data['abilities']
    
    class_data['abilities'].each do |key_id, ability|
      if ability.is_a?(Hash) && (ability['wowhead_id'].nil? || ability['wowhead_id'] == 'null')
        missing << {
          'class' => class_key,
          'class_name' => class_data['name'],
          'key' => key_id,
          'ability_name' => ability['name']
        }
      end
    end
  end
  
  if missing.empty?
    puts "All abilities have spell IDs!"
  else
    puts "Missing spell IDs (#{missing.length} total):\n\n"
    missing.each do |item|
      puts "#{item['class_name']} - #{item['key'].upcase}: #{item['ability_name']}"
    end
  end
end

def main
  if ARGV.empty? || ARGV[0] == '--list' || ARGV[0] == '-l'
    list_missing
  elsif ARGV.length == 3
    class_key = ARGV[0]
    key_id = ARGV[1].downcase
    spell_id = ARGV[2]
    
    update_id(class_key, key_id, spell_id)
  else
    puts "Usage:"
    puts "  ruby _scripts/update-ids.rb [class] [key] [spell_id]"
    puts "  ruby _scripts/update-ids.rb --list  (list all missing IDs)"
    puts ""
    puts "Example:"
    puts "  ruby _scripts/update-ids.rb warrior q 23922"
    puts ""
    puts "Available classes: warrior, paladin, deathknight, demonhunter, druid, monk"
  end
end

main if __FILE__ == $PROGRAM_NAME


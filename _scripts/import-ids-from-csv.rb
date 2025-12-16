#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to import spell IDs from a CSV file
# CSV format: class,key,spell_id,ability_name
# Example:
# warrior,q,23922,Shield Slam
# paladin,e,53595,Hammer of the Righteous

require 'yaml'
require 'csv'

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

def import_from_csv(csv_file)
  keybinds_data = load_keybinds
  updates = []
  errors = []
  
  CSV.foreach(csv_file, headers: true, header_converters: :symbol) do |row|
    class_key = row[:class]&.downcase&.strip
    key_id = row[:key]&.downcase&.strip
    spell_id = row[:spell_id]&.to_i
    ability_name = row[:ability_name]&.strip
    
    unless class_key && key_id && spell_id && spell_id > 0
      errors << "Invalid row: #{row.inspect}"
      next
    end
    
    unless keybinds_data['classes'][class_key]
      errors << "Class '#{class_key}' not found"
      next
    end
    
    unless keybinds_data['classes'][class_key]['abilities'][key_id]
      errors << "Key '#{key_id}' not found for class '#{class_key}'"
      next
    end
    
    old_id = keybinds_data['classes'][class_key]['abilities'][key_id]['wowhead_id']
    keybinds_data['classes'][class_key]['abilities'][key_id]['wowhead_id'] = spell_id
    
    class_name = keybinds_data['classes'][class_key]['name']
    actual_ability_name = keybinds_data['classes'][class_key]['abilities'][key_id]['name']
    
    updates << {
      'class' => class_name,
      'key' => key_id.upcase,
      'ability' => actual_ability_name,
      'old_id' => old_id,
      'new_id' => spell_id
    }
  end
  
  puts "Import Summary"
  puts "=" * 50
  puts "Successfully updated: #{updates.length}"
  
  if updates.any?
    puts "\nUpdates:"
    updates.each do |update|
      puts "  #{update['class']} - #{update['key']} (#{update['ability']})"
      puts "    #{update['old_id'] || 'null'} -> #{update['new_id']}"
    end
  end
  
  if errors.any?
    puts "\nErrors: #{errors.length}"
    errors.each do |error|
      puts "  ✗ #{error}"
    end
  end
  
  if updates.any?
    print "\nSave changes to #{KEYBINDS_FILE}? (y/n): "
    response = STDIN.gets.chomp.downcase
    
    if response == 'y' || response == 'yes'
      save_keybinds(keybinds_data)
      puts "Changes saved!"
    else
      puts "Changes discarded."
    end
  end
end

def generate_template_csv
  keybinds_data = load_keybinds
  template_file = 'spell_ids_template.csv'
  
  CSV.open(template_file, 'w') do |csv|
    csv << ['class', 'key', 'spell_id', 'ability_name']
    
    keybinds_data['classes'].each do |class_key, class_data|
      next unless class_data['abilities']
      
      class_data['abilities'].each do |key_id, ability|
        if ability.is_a?(Hash)
          current_id = ability['wowhead_id'] || ''
          csv << [class_key, key_id, current_id, ability['name']]
        end
      end
    end
  end
  
  puts "Generated template: #{template_file}"
  puts "Fill in the spell_id column and run:"
  puts "  ruby _scripts/import-ids-from-csv.rb #{template_file}"
end

def main
  if ARGV.empty? || ARGV[0] == '--template' || ARGV[0] == '-t'
    generate_template_csv
  elsif File.exist?(ARGV[0])
    import_from_csv(ARGV[0])
  else
    puts "Usage:"
    puts "  ruby _scripts/import-ids-from-csv.rb [csv_file]"
    puts "  ruby _scripts/import-ids-from-csv.rb --template  (generate template CSV)"
    puts ""
    puts "CSV format:"
    puts "  class,key,spell_id,ability_name"
    puts "  warrior,q,23922,Shield Slam"
    puts "  paladin,e,53595,Hammer of the Righteous"
  end
end

main if __FILE__ == $PROGRAM_NAME


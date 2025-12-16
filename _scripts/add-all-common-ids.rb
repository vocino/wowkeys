#!/usr/bin/env ruby
# frozen_string_literal: true

# Adds all common spell IDs automatically (non-interactive)
# Usage: ruby _scripts/add-all-common-ids.rb

require 'yaml'

KEYBINDS_FILE = '_data/keybinds.yml'

# Common spell IDs for all tank abilities
COMMON_IDS = {
  'warrior' => {
    'e' => 6572,      # Revenge
    'r' => 6343,      # Thunder Clap
    'f' => 107574,    # Avatar
    '1' => 1160,      # Demoralizing Shout
    '2' => 190456,    # Ignore Pain
    '3' => 2565,      # Shield Block
    '4' => 23920,     # Spell Reflect
    'z' => 12975,     # Last Stand
    'x' => 152277,    # Ravager
    'c' => 871,       # Shield Wall
    'v' => 97462,     # Rallying Cry
  },
  'paladin' => {
    'q' => 53600,     # Shield of the Righteous
    'e' => 53595,     # Hammer of the Righteous
    'r' => 20271,     # Judgment
    'f' => 31884,     # Avenging Wrath
    '1' => 31935,     # Avenger's Shield
    '2' => 209202,    # Eye of Tyr
    '3' => 304971,    # Divine Toll
    '4' => 85673,     # Word of Glory
    'z' => 86659,     # Guardian of Ancient Kings
    'x' => 26573,     # Consecration
    'c' => 31850,     # Ardent Defender
    'v' => 204150,    # Holy Bulwark
  },
  'deathknight' => {
    'q' => 45470,     # Death Strike
    'e' => 206930,    # Heart Strike
    'r' => 50842,     # Blood Boil
    'f' => 49028,     # Dancing Rune Weapon
    '1' => 195182,    # Marrowrend
    '2' => 48707,     # Anti-Magic Shell
    '3' => 194679,    # Rune Tap
    '4' => 51052,     # Anti-Magic Zone
    'z' => 48792,     # Icebound Fortitude
    'x' => 43265,     # Death and Decay
    'c' => 55233,     # Vampiric Blood
    'v' => 274156,    # Consumption
  },
  'demonhunter' => {
    'q' => 203720,    # Demon Spikes
    'e' => 263642,    # Fracture
    'r' => 213241,    # Felblade
    'f' => 228477,    # Soul Cleave
    '1' => 395428,    # Reaver's Glaive
    '2' => 204596,    # Sigil of Flame
    '3' => 204021,    # Fiery Brand
    '4' => 207407,    # Soul Carver
    'z' => 187827,    # Metamorphosis
    'x' => 204021,    # Fiery Brand (same as 3)
    'c' => 203720,    # Demon Spikes (same as Q)
    'v' => 202137,    # Sigil of Spite
  },
  'druid' => {
    'q' => 33917,     # Mangle
    'e' => 77758,     # Thrash
    'r' => 213771,    # Raze
    'f' => 102558,    # Incarnation: Guardian of Ursoc
    '1' => 8921,      # Moonfire
    '2' => 192081,    # Ironfur
    '3' => 22842,     # Frenzied Regeneration
    '4' => 158298,    # Pulverize
    'z' => 61336,     # Survival Instincts
    'x' => 213771,    # Raze (same as R)
    'c' => 22812,     # Barkskin
    'v' => 124974,    # Nature's Vigil
  },
  'monk' => {
    'q' => 121253,    # Keg Smash
    'e' => 205523,    # Blackout Kick
    'r' => 100780,    # Tiger Palm
    'f' => 115181,    # Breath of Fire
    '1' => 101546,    # Spinning Crane Kick
    '2' => 107428,    # Rising Sun Kick
    '3' => 214326,    # Exploding Keg
    '4' => 322109,    # Touch of Death
    'z' => 115203,    # Fortifying Brew
    'x' => 116847,    # Rushing Jade Wind
    'c' => 119582,    # Purifying Brew
    'v' => 325153,    # Celestial Brew
  }
}

def load_keybinds
  YAML.load_file(KEYBINDS_FILE)
rescue Errno::ENOENT
  puts "Error: #{KEYBINDS_FILE} not found"
  exit 1
end

def save_keybinds(keybinds_data)
  File.write(KEYBINDS_FILE, keybinds_data.to_yaml)
end

def main
  puts "Adding Common Spell IDs"
  puts "=" * 60
  
  keybinds_data = load_keybinds
  updates = []
  
  COMMON_IDS.each do |class_key, abilities|
    next unless keybinds_data['classes'][class_key]
    
    abilities.each do |key_id, spell_id|
      if keybinds_data['classes'][class_key]['abilities'][key_id]
        current_id = keybinds_data['classes'][class_key]['abilities'][key_id]['wowhead_id']
        
        if current_id.nil? || current_id == 'null' || current_id == ''
          ability_name = keybinds_data['classes'][class_key]['abilities'][key_id]['name']
          keybinds_data['classes'][class_key]['abilities'][key_id]['wowhead_id'] = spell_id
          updates << {
            'class' => class_key,
            'key' => key_id,
            'ability' => ability_name,
            'id' => spell_id
          }
        end
      end
    end
  end
  
  if updates.empty?
    puts "No updates needed (all IDs already set)."
    return
  end
  
  puts "Adding #{updates.length} spell IDs...\n\n"
  
  updates.each do |update|
    puts "  #{update['class']} - #{update['key'].upcase}: #{update['ability']} → #{update['id']}"
  end
  
  save_keybinds(keybinds_data)
  puts "\n✓ Updated #{updates.length} spell IDs!"
  puts "\nNext steps:"
  puts "1. Run: ruby _scripts/fetch-abilities-blizzard.rb"
  puts "2. Run: ruby _scripts/preprocess-abilities.rb"
  puts "3. Rebuild Jekyll site"
end

main if __FILE__ == $PROGRAM_NAME


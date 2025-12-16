#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to fetch ability data from WoWHead and cache it
# Usage: ruby _scripts/fetch-abilities.rb

require 'yaml'
require 'json'
require 'net/http'
require 'uri'
require 'fileutils'

KEYBINDS_FILE = '_data/keybinds.yml'
CACHE_FILE = '_data/abilities_cache.yml'
CACHE_DIR = '_data/abilities_cache'

# Ensure cache directory exists
FileUtils.mkdir_p(CACHE_DIR) unless Dir.exist?(CACHE_DIR)

def load_keybinds
  YAML.load_file(KEYBINDS_FILE)
rescue Errno::ENOENT
  puts "Error: #{KEYBINDS_FILE} not found"
  exit 1
end

def load_cache
  return {} unless File.exist?(CACHE_FILE)
  YAML.load_file(CACHE_FILE) || {}
rescue
  {}
end

def save_cache(cache)
  File.write(CACHE_FILE, cache.to_yaml)
end

def fetch_wowhead_data(spell_id)
  # Try multiple WoWHead API endpoints
  endpoints = [
    "https://www.wowhead.com/tooltip/spell/#{spell_id}?dataEnv=1",
    "https://www.wowhead.com/tooltip/spell/#{spell_id}",
    "https://wowhead.com/data=spell;id=#{spell_id}"
  ]
  
  endpoints.each do |endpoint_url|
    uri = URI(endpoint_url)
    
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      request['Accept'] = 'application/json, text/html, */*'
      request['Accept-Language'] = 'en-US,en;q=0.9'
      
      response = http.request(request)
      
      if response.code == '200'
        begin
          # Try to parse as JSON first
          data = JSON.parse(response.body)
          
          # Extract name
          name = data['name'] || data['tooltip']&.match(/<a[^>]*>([^<]+)<\/a>/)&.captures&.first || "Spell #{spell_id}"
          
          # Extract icon - WoWHead uses icon IDs that map to zamimg URLs
          icon_id = data['icon'] || data['iconId'] || data['iconid']
          icon_url = nil
          if icon_id
            icon_url = "https://wow.zamimg.com/images/wow/icons/large/#{icon_id}.jpg"
          end
          
          # Extract tooltip text (strip HTML tags)
          tooltip_html = data['tooltip'] || data['description'] || ''
          tooltip_text = tooltip_html.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
          
          return {
            'name' => name,
            'icon' => icon_url,
            'tooltip' => tooltip_text,
            'wowhead_id' => spell_id.to_s
          }
        rescue JSON::ParserError
          # If not JSON, try parsing HTML response
          html = response.body
          
          # Extract name from HTML
          name_match = html.match(/<a[^>]*class="q[^"]*"[^>]*>([^<]+)<\/a>/)
          name = name_match ? name_match[1] : "Spell #{spell_id}"
          
          # Extract icon ID from HTML
          icon_match = html.match(/iconId['"]?\s*[:=]\s*['"]?(\d+)/)
          icon_id = icon_match ? icon_match[1] : nil
          icon_url = icon_id ? "https://wow.zamimg.com/images/wow/icons/large/#{icon_id}.jpg" : nil
          
          # Extract tooltip
          tooltip_match = html.match(/<div[^>]*class="q[^"]*"[^>]*>([^<]+)/)
          tooltip_text = tooltip_match ? tooltip_match[1] : ''
          
          return {
            'name' => name,
            'icon' => icon_url,
            'tooltip' => tooltip_text,
            'wowhead_id' => spell_id.to_s
          }
        end
      end
    rescue => e
      # Try next endpoint
      next
    end
  end
  
  # If all endpoints failed, try scraping the spell page
  begin
    uri = URI("https://www.wowhead.com/spell=#{spell_id}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    
    response = http.request(request)
    
    if response.code == '200'
      html = response.body
      
      # Extract name from page title or heading
      name_match = html.match(/<h1[^>]*>([^<]+)<\/h1>/) || html.match(/<title>([^<]+)<\/title>/)
      name = name_match ? name_match[1].gsub(/ - WoWHead/, '').strip : "Spell #{spell_id}"
      
      # Extract icon from page
      icon_match = html.match(/iconId['"]?\s*[:=]\s*['"]?(\d+)/) || html.match(/\/icons\/large\/(\d+)\.jpg/)
      icon_id = icon_match ? icon_match[1] : nil
      icon_url = icon_id ? "https://wow.zamimg.com/images/wow/icons/large/#{icon_id}.jpg" : nil
      
      return {
        'name' => name,
        'icon' => icon_url,
        'tooltip' => '',
        'wowhead_id' => spell_id.to_s
      }
    end
  rescue => e
    # Final fallback
  end
  
  puts "Warning: Could not fetch data for spell #{spell_id}"
  nil
end

def collect_ability_ids(keybinds_data)
  ability_ids = []
  
  keybinds_data['classes'].each do |_class_name, class_data|
    next unless class_data['abilities']
    
    class_data['abilities'].each do |_key_id, ability|
      if ability.is_a?(Hash) && ability['wowhead_id'] && 
         ability['wowhead_id'] != 'null' && ability['wowhead_id'] != nil
        ability_ids << ability['wowhead_id'].to_i
      end
    end
  end
  
  ability_ids.uniq
end

def main
  puts "Loading keybinds data..."
  keybinds_data = load_keybinds
  
  puts "Loading existing cache..."
  cache = load_cache
  
  puts "Collecting ability IDs..."
  ability_ids = collect_ability_ids(keybinds_data)
  
  puts "Found #{ability_ids.length} unique ability IDs"
  
  if ability_ids.empty?
    puts "No abilities found in keybinds.yml. Add wowhead_id entries to fetch data."
    return
  end
  
  new_count = 0
  updated_count = 0
  
  ability_ids.each_with_index do |spell_id, index|
    spell_id_str = spell_id.to_s
    
    # Skip if already cached and recent
    if cache[spell_id_str] && cache[spell_id_str]['cached_at']
      puts "[#{index + 1}/#{ability_ids.length}] Skipping #{spell_id} (already cached)"
      next
    end
    
    puts "[#{index + 1}/#{ability_ids.length}] Fetching spell #{spell_id}..."
    
    data = fetch_wowhead_data(spell_id)
    
    if data
      was_new = !cache[spell_id_str]
      data['cached_at'] = Time.now.to_s
      cache[spell_id_str] = data
      
      if was_new
        new_count += 1
      else
        updated_count += 1
      end
      
      # Small delay to avoid rate limiting
      sleep(0.5)
    end
  end
  
  puts "\nSaving cache..."
  save_cache(cache)
  
  puts "\nDone!"
  puts "  New abilities: #{new_count}"
  puts "  Updated abilities: #{updated_count}"
  puts "  Total cached: #{cache.length}"
end

main if __FILE__ == $PROGRAM_NAME


#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to fetch ability data from Blizzard's official Game Data API
# Usage: ruby _scripts/fetch-abilities-blizzard.rb
#
# Requires Blizzard API credentials:
# 1. Get Client ID and Secret from https://develop.battle.net/
# 2. Set environment variables:
#    export BLIZZARD_CLIENT_ID="your_client_id"
#    export BLIZZARD_CLIENT_SECRET="your_client_secret"
# 3. Or create a .env file (not recommended for production)

require 'yaml'
require 'json'
require 'net/http'
require 'uri'
require 'fileutils'
require 'time'

KEYBINDS_FILE = '_data/keybinds.yml'
CACHE_FILE = '_data/abilities_cache.yml'
BLIZZARD_TOKEN_FILE = '_data/.blizzard_token'

# Blizzard API endpoints
OAUTH_URL = 'https://oauth.battle.net/token'
API_BASE = 'https://us.api.blizzard.com'
NAMESPACE = 'static-us'
LOCALE = 'en_US'

def get_client_credentials
  client_id = ENV['BLIZZARD_CLIENT_ID']
  client_secret = ENV['BLIZZARD_CLIENT_SECRET']
  
  # Try reading from .env file if env vars not set
  if (!client_id || !client_secret) && File.exist?('.env')
    File.readlines('.env').each do |line|
      next if line.strip.empty? || line.start_with?('#')
      key, value = line.split('=', 2)
      client_id = value.strip if key&.strip == 'BLIZZARD_CLIENT_ID'
      client_secret = value.strip if key&.strip == 'BLIZZARD_CLIENT_SECRET'
    end
  end
  
  unless client_id && client_secret
    puts "Error: Blizzard API credentials not found!"
    puts ""
    puts "Please set up your credentials:"
    puts "1. Get Client ID and Secret from https://develop.battle.net/"
    puts "2. Set environment variables:"
    puts "   export BLIZZARD_CLIENT_ID=\"your_client_id\""
    puts "   export BLIZZARD_CLIENT_SECRET=\"your_client_secret\""
    puts "3. Or create a .env file with:"
    puts "   BLIZZARD_CLIENT_ID=your_client_id"
    puts "   BLIZZARD_CLIENT_SECRET=your_client_secret"
    exit 1
  end
  
  [client_id, client_secret]
end

def get_access_token(client_id, client_secret, force_refresh = false)
  # Check for cached token
  unless force_refresh && File.exist?(BLIZZARD_TOKEN_FILE)
    begin
      token_data = JSON.parse(File.read(BLIZZARD_TOKEN_FILE))
      expires_at = Time.parse(token_data['expires_at'])
      
      # If token expires in more than 5 minutes, use cached token
      if expires_at > Time.now + 300
        return token_data['access_token']
      end
    rescue
      # If cache is invalid, fetch new token
    end
  end
  
  puts "Fetching Blizzard API access token..."
  
  uri = URI(OAUTH_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri)
  request.basic_auth(client_id, client_secret)
  request.set_form_data('grant_type' => 'client_credentials')
  
  response = http.request(request)
  
  if response.code == '200'
    token_data = JSON.parse(response.body)
    access_token = token_data['access_token']
    expires_in = token_data['expires_in'] || 3600
    
    # Cache token
    FileUtils.mkdir_p(File.dirname(BLIZZARD_TOKEN_FILE))
    File.write(BLIZZARD_TOKEN_FILE, {
      'access_token' => access_token,
      'expires_at' => (Time.now + expires_in).to_s
    }.to_json)
    
    puts "Token obtained (expires in #{expires_in} seconds)"
    return access_token
  else
    puts "Error: Failed to get access token (HTTP #{response.code})"
    puts "Response: #{response.body}"
    exit 1
  end
end

def fetch_spell_from_blizzard(spell_id, access_token)
  uri = URI("#{API_BASE}/data/wow/spell/#{spell_id}")
  uri.query = URI.encode_www_form({
    'namespace' => NAMESPACE,
    'locale' => LOCALE
  })
  
  begin
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10
    
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    request['Accept'] = 'application/json'
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      
      # Extract spell information
      name = data['name'] || "Spell #{spell_id}"
      
      # Get media URL for icon
      icon_url = nil
      if data['media'] && data['media']['key'] && data['media']['key']['href']
        # Blizzard API media structure: media.key.href contains the full URL
        media_url = data['media']['key']['href']
        
        # Parse URL and update namespace if needed (use static-us instead of versioned namespace)
        media_uri = URI(media_url)
        params = URI.decode_www_form(media_uri.query || '').to_h
        params['namespace'] = NAMESPACE
        params['locale'] = LOCALE
        media_uri.query = URI.encode_www_form(params)
        
        media_request = Net::HTTP::Get.new(media_uri)
        media_request['Authorization'] = "Bearer #{access_token}"
        media_request['Accept'] = 'application/json'
        
        media_response = http.request(media_request)
        if media_response.code == '200'
          media_data = JSON.parse(media_response.body)
          if media_data['assets'] && media_data['assets'].is_a?(Array)
            # Find icon asset - Blizzard API uses 'icon' key
            icon_asset = media_data['assets'].find { |a| a['key'] == 'icon' }
            if icon_asset && icon_asset['value']
              icon_url = icon_asset['value']
            end
          end
        end
      end
      
      # Extract description/tooltip
      description = data['description'] || ''
      
      return {
        'name' => name,
        'icon' => icon_url,
        'tooltip' => description,
        'wowhead_id' => spell_id.to_s,
        'source' => 'blizzard_api'
      }
    elsif response.code == '404'
      puts "  Warning: Spell #{spell_id} not found (may be deprecated or invalid)"
      return nil
    else
      puts "  Warning: Failed to fetch spell #{spell_id} (HTTP #{response.code})"
      return nil
    end
  rescue => e
    puts "  Error fetching spell #{spell_id}: #{e.message}"
    return nil
  end
end

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
  puts "Blizzard Game Data API - Ability Fetcher"
  puts "=" * 50
  
  # Get credentials
  client_id, client_secret = get_client_credentials
  
  # Get access token
  access_token = get_access_token(client_id, client_secret)
  
  # Load data
  puts "\nLoading keybinds data..."
  keybinds_data = load_keybinds
  
  puts "Loading existing cache..."
  cache = load_cache
  
  puts "Collecting ability IDs..."
  ability_ids = collect_ability_ids(keybinds_data)
  
  puts "Found #{ability_ids.length} unique ability IDs\n"
  
  if ability_ids.empty?
    puts "No abilities found in keybinds.yml. Add wowhead_id entries to fetch data."
    return
  end
  
  new_count = 0
  updated_count = 0
  failed_count = 0
  
  ability_ids.each_with_index do |spell_id, index|
    spell_id_str = spell_id.to_s
    
    # Skip if already cached and recent (unless it's from WoWHead and we want to update)
    if cache[spell_id_str] && cache[spell_id_str]['cached_at']
      cached_time = Time.parse(cache[spell_id_str]['cached_at'])
      # Refresh if older than 7 days
      if cached_time > Time.now - (7 * 24 * 60 * 60)
        puts "[#{index + 1}/#{ability_ids.length}] Skipping #{spell_id} (already cached)"
        next
      end
    end
    
    puts "[#{index + 1}/#{ability_ids.length}] Fetching spell #{spell_id}..."
    
    data = fetch_spell_from_blizzard(spell_id, access_token)
    
    if data
      was_new = !cache[spell_id_str]
      data['cached_at'] = Time.now.to_s
      # Store with string key (quoted in YAML for Jekyll compatibility)
      cache[spell_id_str] = data
      
      if was_new
        new_count += 1
        puts "  ✓ Fetched: #{data['name']}"
      else
        updated_count += 1
        puts "  ✓ Updated: #{data['name']}"
      end
      
      # Small delay to avoid rate limiting (Blizzard allows reasonable rate)
      sleep(0.2)
    else
      failed_count += 1
    end
  end
  
  puts "\nSaving cache..."
  save_cache(cache)
  
  puts "\nDone!"
  puts "  New abilities: #{new_count}"
  puts "  Updated abilities: #{updated_count}"
  puts "  Failed: #{failed_count}"
  puts "  Total cached: #{cache.length}"
end

main if __FILE__ == $PROGRAM_NAME


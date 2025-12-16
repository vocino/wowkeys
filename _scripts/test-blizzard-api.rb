#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to inspect Blizzard API response structure
require 'json'
require 'net/http'
require 'uri'
require 'time'

def get_client_credentials
  client_id = ENV['BLIZZARD_CLIENT_ID']
  client_secret = ENV['BLIZZARD_CLIENT_SECRET']
  
  if (!client_id || !client_secret) && File.exist?('.env')
    File.readlines('.env').each do |line|
      next if line.strip.empty? || line.start_with?('#')
      key, value = line.split('=', 2)
      client_id = value.strip if key&.strip == 'BLIZZARD_CLIENT_ID'
      client_secret = value.strip if key&.strip == 'BLIZZARD_CLIENT_SECRET'
    end
  end
  
  [client_id, client_secret]
end

def get_access_token(client_id, client_secret)
  uri = URI('https://oauth.battle.net/token')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri)
  request.basic_auth(client_id, client_secret)
  request.set_form_data('grant_type' => 'client_credentials')
  
  response = http.request(request)
  JSON.parse(response.body)['access_token'] if response.code == '200'
end

spell_id = ARGV[0] || '23922'
client_id, client_secret = get_client_credentials
access_token = get_access_token(client_id, client_secret)

puts "Fetching spell #{spell_id} from Blizzard API..."
puts "=" * 60

# Fetch spell data
uri = URI("https://us.api.blizzard.com/data/wow/spell/#{spell_id}")
uri.query = URI.encode_www_form({
  'namespace' => 'static-us',
  'locale' => 'en_US'
})

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Get.new(uri)
request['Authorization'] = "Bearer #{access_token}"
request['Accept'] = 'application/json'

response = http.request(request)

if response.code == '200'
  data = JSON.parse(response.body)
  
  puts "\nSpell Data:"
  puts "  Name: #{data['name']}"
  puts "  ID: #{data['id']}"
  puts "  Description: #{data['description']&.[](0..100)}..."
  
  if data['media']
    puts "\nMedia Object:"
    puts "  Full structure:"
    puts JSON.pretty_generate(data['media'])
    
    # Determine media URL
    media_url = nil
    if data['media']['href'] && !data['media']['href'].empty?
      media_url = "https://us.api.blizzard.com#{data['media']['href']}"
    elsif data['media']['key'] && data['media']['key'].is_a?(Hash) && data['media']['key']['href']
      media_url = data['media']['key']['href']
    end
    
    if media_url
      puts "\nFetching media from: #{media_url}"
      # Fetch media
      media_uri = URI(media_url)
      # Update namespace in query
      params = URI.decode_www_form(media_uri.query || '').to_h
      params['namespace'] = 'static-us'
      params['locale'] = 'en_US'
      media_uri.query = URI.encode_www_form(params)
      
      media_request = Net::HTTP::Get.new(media_uri)
      media_request['Authorization'] = "Bearer #{access_token}"
      media_request['Accept'] = 'application/json'
      
      media_response = http.request(media_request)
      if media_response.code == '200'
        media_data = JSON.parse(media_response.body)
        puts "\nMedia Data:"
        puts "  Full JSON:"
        puts JSON.pretty_generate(media_data)
        
        if media_data['assets']
          puts "\nAssets:"
          media_data['assets'].each do |asset|
            puts "  Key: #{asset['key']}, Value: #{asset['value']}"
          end
        end
      else
        puts "  Failed to fetch media (HTTP #{media_response.code})"
        puts "  Response: #{media_response.body[0..200]}"
      end
    else
      puts "\nNo media URL found in media object"
    end
  else
    puts "\nNo media object found"
  end
else
  puts "Failed to fetch spell (HTTP #{response.code})"
  puts response.body
end


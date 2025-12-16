#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to debug WoWHead API endpoints
require 'net/http'
require 'uri'
require 'json'

spell_id = ARGV[0] || '23922'

puts "Testing WoWHead API endpoints for spell #{spell_id}"
puts "=" * 60

endpoints = [
  "https://www.wowhead.com/tooltip/spell/#{spell_id}",
  "https://www.wowhead.com/tooltip/spell/#{spell_id}?dataEnv=1",
  "https://wowhead.com/data=spell;id=#{spell_id}",
  "https://www.wowhead.com/spell=#{spell_id}"
]

endpoints.each_with_index do |endpoint, i|
  puts "\n[#{i + 1}] Testing: #{endpoint}"
  uri = URI(endpoint)
  
  begin
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 5
    
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    request['Accept'] = 'application/json, text/html, */*'
    
    response = http.request(request)
    
    puts "  Status: #{response.code}"
    puts "  Content-Type: #{response['Content-Type']}"
    puts "  Body length: #{response.body.length} bytes"
    
    if response.code == '200'
      # Try to parse as JSON
      begin
        data = JSON.parse(response.body)
        puts "  ✓ Valid JSON"
        puts "  Keys: #{data.keys.join(', ')}" if data.is_a?(Hash)
        puts "  Sample: #{response.body[0..200]}"
      rescue JSON::ParserError
        puts "  ✗ Not JSON (HTML response)"
        # Look for spell data in HTML
        if response.body.include?('iconId') || response.body.include?('spell=')
          puts "  ✓ Contains spell data indicators"
        end
        puts "  Sample: #{response.body[0..300].gsub(/\s+/, ' ')}"
      end
    else
      puts "  ✗ Failed"
    end
  rescue => e
    puts "  ✗ Error: #{e.message}"
  end
  
  sleep(0.5)
end

puts "\n" + "=" * 60
puts "Test complete. Use this to identify which endpoint works."


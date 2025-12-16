# Jekyll plugin to process ability data and generate static assets
# This runs at build time to embed ability data directly into pages

module Jekyll
  class AbilityProcessor < Generator
    safe true
    priority :normal

    def generate(site)
      # Load keybinds and cache
      keybinds = site.data['keybinds']
      cache = site.data['abilities_cache'] || {}
      
      return unless keybinds && keybinds['classes']
      
      # Process each class and embed ability data
      keybinds['classes'].each do |class_key, class_data|
        next unless class_data['abilities']
        
        # Enhance abilities with cached data
        class_data['abilities'].each do |key_id, ability|
          next unless ability.is_a?(Hash) && ability['wowhead_id']
          
          spell_id = ability['wowhead_id'].to_s
          cached = cache[spell_id] || cache[spell_id.to_i]
          
          if cached
            # Embed cached data directly into ability object
            ability['cached_name'] = cached['name']
            ability['cached_icon'] = cached['icon']
            ability['cached_tooltip'] = cached['tooltip']
          end
        end
      end
    end
  end
end


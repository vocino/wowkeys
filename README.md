# World of Warcraft Tank Keybind Visualizer

A static site generator for visualizing universal tank keybinds across all 6 World of Warcraft tank classes. This project treats tanking as a role-based system, mapping equivalent abilities to the same keys across all classes. It's based on [Quazii's keybind guide video](https://youtu.be/4bCzBstqlF0?si=Okeaoi9JyCeBl7zl), so special thanks to him! Also a lot of discussion about this in the [StratsCo Discord server](https://discord.gg/stratsco).

## Quick Start

### 1. Local Setup

```bash
# Install dependencies
bundle install

# Start the development server
bundle exec jekyll serve
```

Visit `http://localhost:4000` to view the site.

### 2. Set Up Blizzard API (for ability metadata)

The site uses Blizzard's official Game Data API to fetch ability icons and tooltips.

1. **Get API credentials:**
   - Visit https://develop.battle.net/
   - Log in and create a new application
   - Copy your Client ID and Client Secret

2. **Add credentials:**
   Create a `.env` file in the project root:
   ```
   BLIZZARD_CLIENT_ID=your_client_id_here
   BLIZZARD_CLIENT_SECRET=your_client_secret_here
   ```
   
   **Note:** The `.env` file is gitignored - never commit your credentials!

### 3. Change Abilities

Edit `_data/keybinds.yml` to modify which abilities are assigned to which keys for each class.

**Structure:**
```yaml
classes:
  warrior:
    abilities:
      q:
        name: "Shield Slam"
        keybind: "Q"
        wowhead_id: 23922
```

**To change an ability:**
1. Find the class and key in `_data/keybinds.yml`
2. Update the `name` and `wowhead_id` fields
3. If you don't know the spell ID, see "Finding Spell IDs" below

### 4. Get Ability Metadata (Icons & Tooltips)

After updating abilities in `keybinds.yml`, fetch their metadata:

```bash
# Fetch icons and tooltips from Blizzard API
ruby _scripts/fetch-abilities-blizzard.rb

# Merge the cached data into keybinds.yml
ruby _scripts/preprocess-abilities.rb
```

This will:
- Fetch ability icons, names, and tooltips from Blizzard's API
- Cache them in `_data/abilities_cache.yml`
- Merge the data into `_data/keybinds.yml` for Jekyll to use

### 5. Build the Site

```bash
# Build for production
bundle exec jekyll build

# Or serve locally with auto-reload
bundle exec jekyll serve
```

The built site will be in the `_site` directory.

## Finding Spell IDs

If you need to find a spell ID for a new ability:

1. **Manual method:**
   - Go to https://www.wowhead.com
   - Search for the ability name
   - Click the spell page
   - The URL will be like `https://www.wowhead.com/spell=23922`
   - The number after `spell=` is the spell ID

2. **Using the script:**
   ```bash
   ruby _scripts/find-spell-ids.rb "Ability Name"
   ```

3. **Update the ID:**
   ```bash
   ruby _scripts/update-ids.rb [class] [key] [spell_id]
   # Example:
   ruby _scripts/update-ids.rb warrior q 23922
   ```

## Complete Workflow

When adding or changing abilities:

1. **Edit** `_data/keybinds.yml` with ability names and spell IDs
2. **Fetch metadata:** `ruby _scripts/fetch-abilities-blizzard.rb`
3. **Preprocess:** `ruby _scripts/preprocess-abilities.rb`
4. **Build:** `bundle exec jekyll build` or `bundle exec jekyll serve`

## Project Structure

- `_data/keybinds.yml` - Main data file with keys, classes, and abilities
- `_data/abilities_cache.yml` - Cached ability metadata from Blizzard API
- `_scripts/` - Helper scripts for fetching and processing data
- `index.html` - Main spreadsheet view
- `assets/css/spreadsheet.css` - Styling for the spreadsheet layout
- `assets/js/spreadsheet-tooltips.js` - Tooltip functionality

## Deployment

The site is built with Jekyll and can be deployed to:
- **GitHub Pages** (automatic with Jekyll)
- Any static hosting service (Netlify, Vercel, etc.)

Just push the repository and the static files in `_site` will be served.

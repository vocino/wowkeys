# World of Warcraft Tank Keybind Visualizer

A static site for visualizing universal tank keybinds across all 6 World of Warcraft tank classes. This project treats tanking as a role-based system, mapping equivalent abilities to the same keys across all classes. It's based on [Quazii's keybind guide video](https://youtu.be/4bCzBstqlF0?si=Okeaoi9JyCeBl7zl), so special thanks to him! Also a lot of discussion about this in the [StratsCo Discord server](https://discord.gg/stratsco).

Built with [Astro](https://astro.build), deployed to GitHub Pages via GitHub Actions.

## Quick Start

### 1. Local Setup

```bash
# Install dependencies
npm install

# Start the development server
npm run dev
```

Visit `http://localhost:4321/wowkeys/` to view the site.

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

   **Note:** The `.env` file is gitignored — never commit your credentials! Don't wrap the values in quotes.

### 3. Change Abilities

Edit `src/data/keybinds.yml` to modify which abilities are assigned to which keys for each class.

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
1. Find the class and key in `src/data/keybinds.yml`
2. Update the `name` and `wowhead_id` fields
3. If you don't know the spell ID, look it up on [Wowhead](https://www.wowhead.com) — search the ability name, and the number after `spell=` in the URL is the ID

### 4. Get Ability Metadata (Icons & Tooltips)

After updating abilities in `keybinds.yml`, fetch their metadata:

```bash
# Fetch icons and tooltips from Blizzard API
npm run fetch-abilities

# Merge the cached data into keybinds.yml
npm run preprocess-abilities
```

This will:
- Fetch ability icons, names, and tooltips from Blizzard's API
- Cache them in `src/data/abilities_cache.yml`
- Merge the data into `src/data/keybinds.yml` for the site to use

### 5. Build the Site

```bash
# Build for production
npm run build

# Or serve locally with the dev server
npm run dev

# Or preview a production build locally
npm run preview
```

The built site will be in the `dist` directory.

## Other Data Tools

```bash
# Manually set a single ability's spell ID
npm run update-ids -- warrior q 23922

# List every key with a missing spell ID
npm run update-ids -- --list

# Bulk-update via CSV (class,key,spell_id,ability_name)
npm run import-ids -- --template   # generates spell_ids_template.csv
npm run import-ids -- spell_ids_template.csv
```

## Complete Workflow

When adding or changing abilities:

1. **Edit** `src/data/keybinds.yml` with ability names and spell IDs
2. **Fetch metadata:** `npm run fetch-abilities`
3. **Preprocess:** `npm run preprocess-abilities`
4. **Build:** `npm run build` or `npm run dev`

## Project Structure

- `src/data/keybinds.yml` — main data file with keys, classes, and abilities
- `src/data/abilities_cache.yml` — cached ability metadata from Blizzard's API
- `scripts/` — Node/TypeScript tools for fetching and updating ability data
- `src/pages/index.astro` — the page
- `src/layouts/BaseLayout.astro` — page shell (head/meta/header/footer)
- `src/components/` — `KeybindTable.astro` / `KeyRow.astro` / `AbilityCell.astro`
- `src/lib/key-philosophy.ts` — the per-key "philosophy" tooltip text
- `src/lib/cooldown-manager.ts` — Luxthos Cooldown Manager export strings, one per tank spec
- `src/styles/spreadsheet.css` — styling for the spreadsheet layout
- `src/scripts/tooltips.js` — tooltip positioning behavior
- `src/scripts/copy-buttons.js` — clipboard behavior for every `[data-copy-text]` button

## Cooldown Manager Profiles

Each class header carries a `[cdm]` button that copies that spec's [Luxthos Cooldown Manager](https://www.luxthos.com/cooldown-manager-profiles-world-of-warcraft-midnight/) export string. Paste it in-game via the Cooldown Manager's edit mode → Import.

To refresh a profile after Luxthos updates it, replace the matching `code` in `src/lib/cooldown-manager.ts` — the buttons are generated from that file, keyed by class slug.

Any element with a `data-copy-text` attribute becomes a copy button, so the same pattern powers the topbar's `[layout]` button (the WoW Edit Mode UI layout string in `src/consts.ts`).

## Deployment

Pushing to `main` triggers `.github/workflows/pages.yml`, which builds with `npm run build` and deploys `dist/` to GitHub Pages at `vocino.github.io/wowkeys`.

#!/usr/bin/env node
// Ports _scripts/preprocess-abilities.rb — merges src/data/abilities_cache.yml
// into src/data/keybinds.yml (icon/tooltip/cached_name).
// Usage: node scripts/preprocess-abilities.ts

import fs from 'node:fs';
import { parseKeybinds, parseCache, serializeKeybinds } from '../src/lib/keybinds-io.ts';
import { KEYBINDS_PATH, CACHE_PATH } from './paths.ts';

function main() {
	console.log('Preprocessing abilities...');
	console.log(`Loading keybinds from ${KEYBINDS_PATH}...`);
	const keybinds = parseKeybinds(fs.readFileSync(KEYBINDS_PATH, 'utf8'));

	console.log(`Loading cache from ${CACHE_PATH}...`);
	const cache = parseCache(fs.readFileSync(CACHE_PATH, 'utf8'));

	const cacheSize = Object.keys(cache).length;
	if (cacheSize === 0) {
		console.log('Warning: Cache is empty. Run fetch-abilities.ts first.');
	} else {
		console.log(`Found ${cacheSize} cached abilities`);
	}

	console.log('Merging cache into keybinds...');
	for (const classData of Object.values(keybinds.classes)) {
		for (const ability of Object.values(classData.abilities ?? {})) {
			if (!ability?.wowhead_id) continue;
			const cached = cache[String(ability.wowhead_id)];
			if (cached) {
				ability.icon = cached.icon ?? undefined;
				ability.tooltip = cached.tooltip;
				ability.cached_name = cached.name;
			}
		}
	}

	console.log(`Saving to ${KEYBINDS_PATH}...`);
	fs.writeFileSync(KEYBINDS_PATH, serializeKeybinds(keybinds), 'utf8');

	console.log('Done! Ability data is now embedded in keybinds.yml');
	console.log('You can now build Astro and the icons will appear.');
}

main();

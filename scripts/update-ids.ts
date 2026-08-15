#!/usr/bin/env node
// Ports _scripts/update-ids.rb — manually update a spell ID in keybinds.yml.
// Usage: node scripts/update-ids.ts [class] [key] [spell_id]
// Example: node scripts/update-ids.ts warrior q 23922

import fs from 'node:fs';
import { parseKeybinds, serializeKeybinds } from '../src/lib/keybinds-io.ts';
import { KEYBINDS_PATH } from './paths.ts';
import type { KeybindsData } from '../src/lib/types.ts';

function loadKeybinds(): KeybindsData {
	return parseKeybinds(fs.readFileSync(KEYBINDS_PATH, 'utf8'));
}

function saveKeybinds(data: KeybindsData): void {
	fs.writeFileSync(KEYBINDS_PATH, serializeKeybinds(data), 'utf8');
}

function updateId(classKey: string, keyId: string, spellId: string): boolean {
	const keybinds = loadKeybinds();
	const classData = keybinds.classes[classKey];

	if (!classData) {
		console.log(`Error: Class '${classKey}' not found`);
		console.log(`Available classes: ${Object.keys(keybinds.classes).join(', ')}`);
		return false;
	}

	const ability = classData.abilities[keyId];
	if (!ability) {
		console.log(`Error: Key '${keyId}' not found for class '${classKey}'`);
		return false;
	}

	const oldId = ability.wowhead_id;
	ability.wowhead_id = Number(spellId);

	console.log(`Updated: ${classData.name} - ${keyId.toUpperCase()} (${ability.name})`);
	console.log(`  Old ID: ${oldId ?? 'null'}`);
	console.log(`  New ID: ${spellId}`);

	saveKeybinds(keybinds);
	console.log(`Changes saved to ${KEYBINDS_PATH}`);
	return true;
}

function listMissing(): void {
	const keybinds = loadKeybinds();
	const missing: { className: string; key: string; abilityName: string }[] = [];

	for (const classData of Object.values(keybinds.classes)) {
		for (const [keyId, ability] of Object.entries(classData.abilities ?? {})) {
			const id = ability?.wowhead_id;
			if (id === undefined || id === null || String(id) === 'null') {
				missing.push({ className: classData.name, key: keyId, abilityName: ability.name });
			}
		}
	}

	if (missing.length === 0) {
		console.log('All abilities have spell IDs!');
	} else {
		console.log(`Missing spell IDs (${missing.length} total):\n`);
		for (const item of missing) {
			console.log(`${item.className} - ${item.key.toUpperCase()}: ${item.abilityName}`);
		}
	}
}

function main(): void {
	const args = process.argv.slice(2);

	if (args.length === 0 || args[0] === '--list' || args[0] === '-l') {
		listMissing();
	} else if (args.length === 3) {
		const [classKey, keyArg, spellId] = args;
		updateId(classKey, keyArg.toLowerCase(), spellId);
	} else {
		console.log('Usage:');
		console.log('  node scripts/update-ids.ts [class] [key] [spell_id]');
		console.log('  node scripts/update-ids.ts --list  (list all missing IDs)');
		console.log('');
		console.log('Example:');
		console.log('  node scripts/update-ids.ts warrior q 23922');
		console.log('');
		console.log('Available classes: warrior, paladin, deathknight, demonhunter, druid, monk');
	}
}

main();

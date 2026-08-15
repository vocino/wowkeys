#!/usr/bin/env node
// Ports _scripts/import-ids-from-csv.rb — bulk-import spell IDs from a CSV
// file (class,key,spell_id,ability_name). Usage:
//   node scripts/import-ids-from-csv.ts [csv_file]
//   node scripts/import-ids-from-csv.ts --template

import fs from 'node:fs';
import readline from 'node:readline/promises';
import { parseKeybinds, serializeKeybinds } from '../src/lib/keybinds-io.ts';
import { KEYBINDS_PATH } from './paths.ts';
import type { KeybindsData } from '../src/lib/types.ts';

function loadKeybinds(): KeybindsData {
	return parseKeybinds(fs.readFileSync(KEYBINDS_PATH, 'utf8'));
}

function saveKeybinds(data: KeybindsData): void {
	fs.writeFileSync(KEYBINDS_PATH, serializeKeybinds(data), 'utf8');
}

// Minimal parser for the plain 4-column format this project uses
// (class,key,spell_id,ability_name) — no quoted/embedded commas expected,
// same assumption the original Ruby CSV-based script made in practice.
function parseCsv(content: string): Record<string, string>[] {
	const lines = content.split(/\r?\n/).filter((line) => line.trim() !== '');
	const [headerLine, ...rows] = lines;
	const headers = headerLine.split(',').map((h) => h.trim().toLowerCase());
	return rows.map((line) => {
		const cells = line.split(',');
		const row: Record<string, string> = {};
		headers.forEach((header, i) => {
			row[header] = (cells[i] ?? '').trim();
		});
		return row;
	});
}

async function importFromCsv(csvFile: string): Promise<void> {
	const keybinds = loadKeybinds();
	const updates: { class: string; key: string; ability: string; oldId: unknown; newId: number }[] = [];
	const errors: string[] = [];

	const rows = parseCsv(fs.readFileSync(csvFile, 'utf8'));

	for (const row of rows) {
		const classKey = row.class?.toLowerCase();
		const keyId = row.key?.toLowerCase();
		const spellId = Number(row.spell_id);

		if (!classKey || !keyId || !spellId || spellId <= 0) {
			errors.push(`Invalid row: ${JSON.stringify(row)}`);
			continue;
		}

		const classData = keybinds.classes[classKey];
		if (!classData) {
			errors.push(`Class '${classKey}' not found`);
			continue;
		}

		const ability = classData.abilities[keyId];
		if (!ability) {
			errors.push(`Key '${keyId}' not found for class '${classKey}'`);
			continue;
		}

		const oldId = ability.wowhead_id;
		ability.wowhead_id = spellId;

		updates.push({ class: classData.name, key: keyId.toUpperCase(), ability: ability.name, oldId, newId: spellId });
	}

	console.log('Import Summary');
	console.log('='.repeat(50));
	console.log(`Successfully updated: ${updates.length}`);

	if (updates.length > 0) {
		console.log('\nUpdates:');
		for (const u of updates) {
			console.log(`  ${u.class} - ${u.key} (${u.ability})`);
			console.log(`    ${u.oldId ?? 'null'} -> ${u.newId}`);
		}
	}

	if (errors.length > 0) {
		console.log(`\nErrors: ${errors.length}`);
		for (const e of errors) console.log(`  ✗ ${e}`);
	}

	if (updates.length > 0) {
		const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
		const response = (await rl.question(`\nSave changes to ${KEYBINDS_PATH}? (y/n): `)).trim().toLowerCase();
		rl.close();

		if (response === 'y' || response === 'yes') {
			saveKeybinds(keybinds);
			console.log('Changes saved!');
		} else {
			console.log('Changes discarded.');
		}
	}
}

function generateTemplateCsv(): void {
	const keybinds = loadKeybinds();
	const templateFile = 'spell_ids_template.csv';
	const lines = ['class,key,spell_id,ability_name'];

	for (const [classKey, classData] of Object.entries(keybinds.classes)) {
		for (const [keyId, ability] of Object.entries(classData.abilities ?? {})) {
			lines.push(`${classKey},${keyId},${ability.wowhead_id ?? ''},${ability.name}`);
		}
	}

	fs.writeFileSync(templateFile, lines.join('\n') + '\n', 'utf8');
	console.log(`Generated template: ${templateFile}`);
	console.log('Fill in the spell_id column and run:');
	console.log(`  node scripts/import-ids-from-csv.ts ${templateFile}`);
}

async function main(): Promise<void> {
	const args = process.argv.slice(2);

	if (args.length === 0 || args[0] === '--template' || args[0] === '-t') {
		generateTemplateCsv();
	} else if (fs.existsSync(args[0])) {
		await importFromCsv(args[0]);
	} else {
		console.log('Usage:');
		console.log('  node scripts/import-ids-from-csv.ts [csv_file]');
		console.log('  node scripts/import-ids-from-csv.ts --template  (generate template CSV)');
		console.log('');
		console.log('CSV format:');
		console.log('  class,key,spell_id,ability_name');
		console.log('  warrior,q,23922,Shield Slam');
		console.log('  paladin,e,53595,Hammer of the Righteous');
	}
}

main();

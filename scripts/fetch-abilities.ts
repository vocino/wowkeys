#!/usr/bin/env node
// Ports _scripts/fetch-abilities-blizzard.rb — fetches ability data from
// Blizzard's official Game Data API and caches it in src/data/abilities_cache.yml.
// Usage: node scripts/fetch-abilities.ts
//
// Requires Blizzard API credentials:
// 1. Get a Client ID and Secret from https://develop.battle.net/
// 2. Set BLIZZARD_CLIENT_ID / BLIZZARD_CLIENT_SECRET as env vars, or in a
//    gitignored .env file at the repo root.

import fs from 'node:fs';
import { parseKeybinds, parseCache, serializeCache } from '../src/lib/keybinds-io.ts';
import { KEYBINDS_PATH, CACHE_PATH, TOKEN_PATH, ENV_PATH } from './paths.ts';
import type { AbilitiesCache, KeybindsData } from '../src/lib/types.ts';

const OAUTH_URL = 'https://oauth.battle.net/token';
const API_BASE = 'https://us.api.blizzard.com';
const NAMESPACE = 'static-us';
const LOCALE = 'en_US';
const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

function getClientCredentials(): { clientId: string; clientSecret: string } {
	let clientId = process.env.BLIZZARD_CLIENT_ID;
	let clientSecret = process.env.BLIZZARD_CLIENT_SECRET;

	if ((!clientId || !clientSecret) && fs.existsSync(ENV_PATH)) {
		try {
			process.loadEnvFile(ENV_PATH);
			clientId ??= process.env.BLIZZARD_CLIENT_ID;
			clientSecret ??= process.env.BLIZZARD_CLIENT_SECRET;
		} catch {
			// fall through to the missing-credentials error below
		}
	}

	if (!clientId || !clientSecret) {
		console.log('Error: Blizzard API credentials not found!\n');
		console.log('Please set up your credentials:');
		console.log('1. Get Client ID and Secret from https://develop.battle.net/');
		console.log('2. Set environment variables:');
		console.log('   export BLIZZARD_CLIENT_ID="your_client_id"');
		console.log('   export BLIZZARD_CLIENT_SECRET="your_client_secret"');
		console.log('3. Or create a .env file with:');
		console.log('   BLIZZARD_CLIENT_ID=your_client_id');
		console.log('   BLIZZARD_CLIENT_SECRET=your_client_secret');
		process.exit(1);
	}

	return { clientId, clientSecret };
}

interface TokenCache {
	access_token: string;
	expires_at: string;
}

async function getAccessToken(clientId: string, clientSecret: string): Promise<string> {
	if (fs.existsSync(TOKEN_PATH)) {
		try {
			const tokenData: TokenCache = JSON.parse(fs.readFileSync(TOKEN_PATH, 'utf8'));
			const expiresAt = new Date(tokenData.expires_at).getTime();
			if (expiresAt > Date.now() + 5 * 60 * 1000) {
				return tokenData.access_token;
			}
		} catch {
			// cache invalid/missing — fetch a new token below
		}
	}

	console.log('Fetching Blizzard API access token...');

	const response = await fetch(OAUTH_URL, {
		method: 'POST',
		headers: {
			Authorization: `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
			'Content-Type': 'application/x-www-form-urlencoded',
		},
		body: new URLSearchParams({ grant_type: 'client_credentials' }),
	});

	if (!response.ok) {
		console.log(`Error: Failed to get access token (HTTP ${response.status})`);
		console.log(`Response: ${await response.text()}`);
		process.exit(1);
	}

	const tokenData = await response.json();
	const accessToken: string = tokenData.access_token;
	const expiresIn: number = tokenData.expires_in ?? 3600;

	fs.writeFileSync(
		TOKEN_PATH,
		JSON.stringify({
			access_token: accessToken,
			expires_at: new Date(Date.now() + expiresIn * 1000).toString(),
		}),
	);

	console.log(`Token obtained (expires in ${expiresIn} seconds)`);
	return accessToken;
}

interface FetchedAbility {
	name: string;
	icon: string | null;
	tooltip: string;
	wowhead_id: string;
	source: string;
}

async function fetchSpellFromBlizzard(spellId: number, accessToken: string): Promise<FetchedAbility | null> {
	const url = new URL(`${API_BASE}/data/wow/spell/${spellId}`);
	url.searchParams.set('namespace', NAMESPACE);
	url.searchParams.set('locale', LOCALE);

	try {
		const response = await fetch(url, {
			headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/json' },
			signal: AbortSignal.timeout(10_000),
		});

		if (response.status === 404) {
			console.log(`  Warning: Spell ${spellId} not found (may be deprecated or invalid)`);
			return null;
		}
		if (!response.ok) {
			console.log(`  Warning: Failed to fetch spell ${spellId} (HTTP ${response.status})`);
			return null;
		}

		const data = await response.json();
		const name: string = data.name || `Spell ${spellId}`;

		let iconUrl: string | null = null;
		const mediaHref = data.media?.key?.href;
		if (mediaHref) {
			const mediaUrl = new URL(mediaHref);
			mediaUrl.searchParams.set('namespace', NAMESPACE);
			mediaUrl.searchParams.set('locale', LOCALE);

			const mediaResponse = await fetch(mediaUrl, {
				headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/json' },
			});
			if (mediaResponse.ok) {
				const mediaData = await mediaResponse.json();
				const iconAsset = mediaData.assets?.find((a: { key: string }) => a.key === 'icon');
				iconUrl = iconAsset?.value ?? null;
			}
		}

		return {
			name,
			icon: iconUrl,
			tooltip: data.description ?? '',
			wowhead_id: String(spellId),
			source: 'blizzard_api',
		};
	} catch (e) {
		console.log(`  Error fetching spell ${spellId}: ${(e as Error).message}`);
		return null;
	}
}

function collectAbilityIds(keybinds: KeybindsData): number[] {
	const ids = new Set<number>();
	for (const classData of Object.values(keybinds.classes)) {
		for (const ability of Object.values(classData.abilities ?? {})) {
			const raw = ability?.wowhead_id;
			if (raw !== undefined && raw !== null && String(raw) !== 'null') {
				ids.add(Number(raw));
			}
		}
	}
	return [...ids];
}

function sleep(ms: number): Promise<void> {
	return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
	console.log('Blizzard Game Data API - Ability Fetcher');
	console.log('='.repeat(50));

	const { clientId, clientSecret } = getClientCredentials();
	const accessToken = await getAccessToken(clientId, clientSecret);

	console.log('\nLoading keybinds data...');
	const keybinds = parseKeybinds(fs.readFileSync(KEYBINDS_PATH, 'utf8'));

	console.log('Loading existing cache...');
	const cache: AbilitiesCache = fs.existsSync(CACHE_PATH) ? parseCache(fs.readFileSync(CACHE_PATH, 'utf8')) : {};

	console.log('Collecting ability IDs...');
	const abilityIds = collectAbilityIds(keybinds);
	console.log(`Found ${abilityIds.length} unique ability IDs\n`);

	if (abilityIds.length === 0) {
		console.log('No abilities found in keybinds.yml. Add wowhead_id entries to fetch data.');
		return;
	}

	let newCount = 0;
	let updatedCount = 0;
	let failedCount = 0;

	for (let i = 0; i < abilityIds.length; i++) {
		const spellId = abilityIds[i];
		const spellIdStr = String(spellId);
		const cached = cache[spellIdStr];

		if (cached?.cached_at) {
			const cachedTime = new Date(cached.cached_at).getTime();
			if (cachedTime > Date.now() - SEVEN_DAYS_MS) {
				console.log(`[${i + 1}/${abilityIds.length}] Skipping ${spellId} (already cached)`);
				continue;
			}
		}

		console.log(`[${i + 1}/${abilityIds.length}] Fetching spell ${spellId}...`);
		const data = await fetchSpellFromBlizzard(spellId, accessToken);

		if (data) {
			const wasNew = !cache[spellIdStr];
			cache[spellIdStr] = { ...data, cached_at: new Date().toString() };

			if (wasNew) {
				newCount++;
				console.log(`  ✓ Fetched: ${data.name}`);
			} else {
				updatedCount++;
				console.log(`  ✓ Updated: ${data.name}`);
			}

			await sleep(200);
		} else {
			failedCount++;
		}
	}

	console.log('\nSaving cache...');
	fs.writeFileSync(CACHE_PATH, serializeCache(cache), 'utf8');

	console.log('\nDone!');
	console.log(`  New abilities: ${newCount}`);
	console.log(`  Updated abilities: ${updatedCount}`);
	console.log(`  Failed: ${failedCount}`);
	console.log(`  Total cached: ${Object.keys(cache).length}`);
}

main();

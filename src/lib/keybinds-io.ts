import YAML from 'yaml';
import type { KeybindsData, AbilitiesCache } from './types.ts';

// Pure parse/serialize only — no filesystem access here. Astro pages get their
// raw YAML text via Vite's `?raw` import (bundled at build time); the Node
// scripts under scripts/ read/write the files directly via fs. Both share
// this module for the actual YAML <-> typed-object logic.

export function parseKeybinds(raw: string): KeybindsData {
	return YAML.parse(raw);
}

export function serializeKeybinds(data: KeybindsData): string {
	return YAML.stringify(data);
}

export function parseCache(raw: string): AbilitiesCache {
	return YAML.parse(raw) ?? {};
}

export function serializeCache(data: AbilitiesCache): string {
	return YAML.stringify(data);
}

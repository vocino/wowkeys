export interface KeyDef {
	id: string;
	priority: 's' | 'a' | 'b';
	label: string;
	note?: string;
}

export interface Ability {
	name: string;
	keybind: string;
	wowhead_id: number;
	icon?: string;
	tooltip?: string;
	cached_name?: string;
}

export interface ClassData {
	name: string;
	slug: string;
	display_name: string;
	abilities: Record<string, Ability>;
}

export interface KeybindsData {
	keys: {
		s_tier: KeyDef[];
		a_tier: KeyDef[];
		b_tier: KeyDef[];
		mouse: KeyDef[];
	};
	classes: Record<string, ClassData>;
}

export interface CachedAbility {
	name: string;
	icon: string | null;
	tooltip: string;
	wowhead_id: string;
	source: string;
	cached_at: string;
}

export type AbilitiesCache = Record<string, CachedAbility>;

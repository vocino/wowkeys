// Single source of truth for the per-key "philosophy" tooltip text.
// Previously this was four separate, drifting {% case %} blocks in index.html.
const KEY_PHILOSOPHY: Record<string, string> = {
	mouse4: 'Interrupt (Mind Freeze, Disrupt, Skull Bash, Spear Hand Strike, Rebuke, Pummel)',
	mouse5: 'Taunt (Dark Command, Torment, Growl, Provoke, Hand of Reckoning, Taunt)',

	q: 'Primary Active Mitigation (Heart Strike, Fracture, Mangle, Keg Smash, Judgment, Shield Slam)',
	e: 'Secondary Attack/Generator (Death Strike, Soul Cleave, Thrash, Blackout Kick, Hammer of the Righteous, Revenge)',
	r: "Basic Filler/Builder (Blood Boil, Immolation Aura, Swipe, Tiger Palm, Avenger's Shield, Thunder Clap)",
	f: 'Major Offensive CD (Dancing Rune Weapon, Metamorphosis, Incarnation: Guardian of Ursoc, Breath of Fire, Avenging Wrath, Avatar)',
	'1': 'Heal/Recovery (Death Pact, Fel Devastation, Frenzied Regeneration, Expel Harm, Word of Glory, Impending Victory)',
	'2': 'Quick Mitigation/Utility (Anti-Magic Shell, Spirit Bomb, Moonfire, Spinning Crane Kick, Divine Shield, Ignore Pain)',
	'3': 'Major Defensive/Utility (Marrowrend, Demon Spikes, Ironfur, Purifying Brew, Shield of the Righteous, Shield Block)',
	'4': 'Heal/Utility/Alternate (Consumption, Sigil of Silence, Sundering Roar, Touch of Death, Divine Toll, Spell Reflection)',

	z: 'Emergency Button (Icebound Fortitude, Fiery Brand, Survival Instincts, Fortifying Brew, Ardent Defender, Last Stand)',
	x: "Ground-Targeted AoE (Death and Decay, Sigil of Flame, Ursol's Vortex, Rushing Jade Wind, Consecration, Ravager)",
	c: 'Major Defensive Wall (Vampiric Blood, Darkness, Barkskin, Celestial Brew, Guardian of Ancient Kings, Shield Wall)',
	v: 'Group/Alternative Utility (Anti-Magic Zone, Sigil of Chains, Stampeding Roar, Summon Black Ox Statue, Holy Bulwark, Rallying Cry)',
	g: "Movement (Death's Advance, Infernal Strike, Wild Charge, Roll, Divine Steed, Heroic Leap)",
	'5': 'A-Tier utility key (Warrior: Shield Charge)',
	tilde: 'A-Tier utility key',

	'6': 'B-Tier utility key (Warrior: Demoralizing Shout)',
	t: 'B-Tier utility key',
	y: 'B-Tier utility key',
	h: "Legion Class Mount (Deathlord's Vilebrood Vanquisher, Slayer's Felbroken Shrieker, Archdruid's Lunarwing Form, Ban-Lu Grandmaster's Companion, Highlord's Golden Charger, Battlelord's Bloodthirsty War Wyrm)",
	b: 'B-Tier utility key',
};

export function getKeyPhilosophy(keyId: string): string {
	return KEY_PHILOSOPHY[keyId] ?? '';
}

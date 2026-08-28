// Luxthos Cooldown Manager export strings, one per tank spec.
// Paste in-game via the Cooldown Manager's edit mode > Import.
// Source: https://www.luxthos.com/cooldown-manager-profiles-world-of-warcraft-midnight/

export interface CooldownManagerProfile {
	/** Spec name as Luxthos publishes it. */
	spec: string;
	/** Wago page the export string came from. */
	source: string;
	/** The raw import string. */
	code: string;
}

const COOLDOWN_MANAGER_PROFILES: Record<string, CooldownManagerProfile> = {
	deathknight: {
		spec: 'Blood Death Knight',
		source: 'https://wago.io/LuxthosDeathKnightBloodCDM',
		code: "1|PdA/TFNRFAbwc0+pohVluvE7Dq96WRSJTG5d0M3BhEF8YxNbSmLsYNXIJNZAQuJoFLfGQNLNyYmFdEIJ/oHNFQZaChX/RSfzvb64/L57b96978t5ln3SOFtoZOuvbuH9MnwPcQbxAPwh1nvwe/BdhAJ8G9EnRB8RcghDiDZN9FqMaBvhFPw+oi8IZxBOo/UCO6OIthB9NnHFAxMtrSIsm7iZBwhrzIcIN0001+TmEXnM5zbRmuRmlhfbJq6zSKYw4k305AaP9xFWmF3yjfwgP8kv8pv8NXE7RyZud8HEtZ8TbosdE335jqvv5MhEh6om+nXbJDP4lmX/mGj5KrlPeFbumuh02UQr58htEpvo0q6Jvr5skjkxbJI5/oFs8KmL5BK5QsbJKOHHg2O8ceGNzv+v00k7aWk1LeaKB/mnSStEW+cXkwElM8GIR1hDazKZoutMpcPRXBNhpQm/N1dXdwy+nWY3zcN+hkI/44F+rveSTP44V9esS1okq0a2dr1UrFXyN+7NTFdq+bH8xN1q9c4/",
	},
	demonhunter: {
		spec: 'Vengeance Demon Hunter',
		source: 'https://wago.io/LuxthosDemonHunterVengeanceCDM',
		code: "1|NZFLL0NhEIbnTNGKFSvvrMpCgjkhsbeycNk4C+oSmmoOulAhhHTFaZXEJexsSETj8gf8AFuW+BliIU0khMzX2jzvZCZf5n3nKzXuXLUXomrxfBjBMoIy9AbBNbSMIAedh84hqECz0DS0BH9UKJb4FPK+rw3j0CI0gs5Cp6AL0AnoJHQGmoJOQzNCHOsSYl6E3iIYE+KGDyGmEZs8CrH3ha1nIR4dhB8X8jIp+M3Y2ofeCXm/BWul4b8IceMu/ITpuxDHH+zRmhAf2+z0TYjPWg1tQnz0Y4MBIT5psSpneBXiw6oQP10I8filUCz+ZHi2WN2GHkOfod/Qa1CDLxRr7qxQBC276BzVTOttsvh/GOhex4F5W3Hu3QoXKF4z7qI39N1D53aL7DVB5+uarmu2rqWaBrm6Vpy6xVZ57gtcL6putw+FK6v55PBmfiNcT/rJyTC/FGby2fAP",
	},
	druid: {
		spec: 'Guardian Druid',
		source: 'https://wago.io/LuxthosDruidGuardianCDM',
		code: "1|RdK/T1NRFAfwc+8De99rlyYO/Z44VCO/Jbow6OJi7B+AkZ+SR8JSSAhgCJuRljgA7i6EdDA6ENgcjYNOuMAmDJQf0kLZgI0E8r0tYfmcc8999+bk3LfQ/LGUmS4FxS+D6P+D/t8qJrQq9sc6XFXFJGpwZRVjrxAtqdjXm1jsQbSMMK1i4gkVm6mSE3KqYlwaURuiF3AHcPtwx5h7DHcId4QP47yRHyVO4PYYq3BNcKcqtvc5XA3Zlyp2+5J396kEYYCowsUb8hapGKkVJGMkcyo2d5/VATJEhsk7MqJi8j/JLxWzq2xuj5TJPjkgh+SI/CcVUlOxD76R7yq2lRvtqyp2q1UlcP94/TibPGethdmFit14z91r9izEkCbWdlSCxCb5y2UH6SRPyTPSRZ6Qbh579FUK/g38AxjmmTNEn+2Cn8LdhBBVsgU/c9/aw09I5pCKfTv1QXGwhTW48nzRmntw1XoM0/UYLTXicj0u9vjoH/w2S9Rus7hvvmibjf8NGjW7fdmoBWHgs1Iw9WpmNj+W7c7mZkdnxvKjkzc=",
	},
	monk: {
		spec: 'Brewmaster Monk',
		source: 'https://wago.io/LuxthosMonkBrewmasterCDM',
		code: "1|LdFNS1tBGAXguRPTxF9Qz4DkWoV5jRWLP6Hb4qJaXSml0ECrxrQqt9teIl10JdnoqhLciZsu/BM1fkA1TZW2yrgWwY80idRyxmyeM+8wDMyZpeTHclcuLq5OIZpFlEc0B/sP9s6oIHOOqISoAGlBFETDDWNrBbYFewt7DfcD9ga2ATcJ9wmuCluH/QtXg23CpeDSRiXSE5Br9HdD0kYFYQ/kEpKCXBkVvDyBJCE3yF5gYAhyC6lze9uo4M0yVztkl+yRfZx1QJpcficH5JDUyE9Ig3lEjskv8pv8IafEGaW735Jpo3Tmm1E6fEhek69G6d5NUjdK91WN0u8qRunyMz7mC6mRUTJGXpBxskaeG5VIbZMKx36SJUPkCRkgj8mgUYnOR+s69m2Esb++57Ovgs34C1mPNHxDdUgTZx0bsHdxUQcPIKqdmhlAEu25dZ9RoZ2l+3TD/pz/X7/jvygu6mQQvx8pzM2Eg+HT+dyH/KuFxdz8fw==",
	},
	paladin: {
		spec: 'Protection Paladin',
		source: 'https://wago.io/LuxthosPaladinProtectionCDM',
		code: "1|PdA7SwNBFAXg2QnxgdoGzlRJrDQR768QX2BU7I1PImpAs4lvzG4kaqHYaHxhYlJYWtkINpb6EyxVSJkmtZx1SfPde4aBGU4heFgJOU23NIP3bthbsLeN0m9rkDykCHEhDqRglNU1BrmA2JADyBbkEJLjcS/kDLIP2UO2B7IN2YHsQrKQE6N0PYT3V9i7Rlmz02SEDENOkWtAjpmGkI1BzvHzwjRKxskESZBJMmWUtVIlD6RGyqRCHo3SWDZKmyhJGqUjcbJEyqRCeC/yZZSOTpCEUYHgN/kxKtDxzG2OVBkvyRUpkWtyQ27JHbk3KtD+QT4Z+0g/GSRCYiROBowKdEZryvEK9ZrWR14h/1WxMr+i6bDjfQj2TqTYKghyzOp+I8g1niD5vKutNojjT9efBX8Wvek91to2/U3XQ3lXBy2nmUkkV5MLqfXwQDixkc4szmdS6fU/",
	},
	warrior: {
		spec: 'Protection Warrior',
		source: 'https://wago.io/LuxthosWarriorProtectionCDM',
		code: "1|LdC/S1tRFAfwe9/TxFhTg6XS72lifg/aSoWie7fvorZdMjmoiLg0EDKL4aW1tGo76hgQ7CJInEr2guhQOuk/0ODsUrCDfMNbPt9zufdy7znt4Z1OuhNGhzXwOZgDs2AefAQOgeNgESyDGTABhmDJnD925sKRM3RvQQNHwST4BL1/4DNwDHwMjuDPXzAFpsEJ8Ck4ie4PEGAFrJrza2/w/yd6ZfTvzfnNZXNB7tScv86LrMhp4514b87/jlStqGqLz+Kj+CR2zfn5O/TNXDD1Wosj8cucXyiIJbEoltVEYM7fpFR5vaUj11Pmgu09sS8OxDfxRXwV380F5xfmwlRFU9gzFyYvxZWW02JGvBJz4oV4KWZ1rXTsW+BYEIFV9O/BSqE1mGcxGnxm0IHfXDkBw1YU+ASYiHM8zkycxThLcZYH2QmbtdVGY6veKMwW3jbqzY315lb9wwM=",
	},
};

export function getCooldownManagerProfile(classSlug: string): CooldownManagerProfile | undefined {
	return COOLDOWN_MANAGER_PROFILES[classSlug];
}

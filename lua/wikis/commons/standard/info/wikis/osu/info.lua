---
-- @Liquipedia
-- wiki=osu
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2007,
	wikiName = 'osu',
	name = 'osu!',
	defaultGame = 'osu',
	games = {
		osu = {
			abbreviation = 'osu!',
			name = 'osu!',
			link = 'osu!',
			logo = {
				darkMode = 'Osu! stable allmode.png',
				lightMode = 'Osu! stable allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Osu! stable allmode.png',
				lightMode = 'Osu! stable allmode.png',
			},
		},
		lazer = {
			abbreviation = 'osu!lazer',
			name = 'osu!lazer',
			link = 'osu!lazer',
			logo = {
				darkMode = 'osu! allmode.png',
				lightMode = 'osu! allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'osu! default allmode.png',
				lightMode = 'osu! default allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			status = 2,
			matchWidth = 180,
		},
	},
	defaultRoundPrecision = 0,
}

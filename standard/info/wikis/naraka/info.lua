---
-- @Liquipedia
-- wiki=naraka
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2021,
	wikiName = 'naraka',
	name = 'Naraka: Bladepoint',
	defaultGame = 'naraka',
	games = {
		naraka = {
			abbreviation = 'Naraka',
			name = 'Naraka: Bladepoint',
			link = 'Naraka: Bladepoint',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'NARAKA darkmode.png',
				lightMode = 'NARAKA lightmode.png',
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
			status = 0,
		},
	},
}

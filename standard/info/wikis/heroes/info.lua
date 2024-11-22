---
-- @Liquipedia
-- wiki=heroes
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2014,
	wikiName = 'heroes',
	name = 'Heroes of the Storm',
	defaultGame = 'hots',
	games = {
		hots = {
			abbreviation = 'Heroes',
			name = 'Heroes of the Storm',
			link = 'Heroes of the Storm',
			logo = {
				darkMode = 'Heroes of the Storm default allmode.png',
				lightMode = 'Heroes of the Storm default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Heroes of the Storm default allmode.png',
				lightMode = 'Heroes of the Storm default allmode.png',
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
			matchWidthMobile = 110,
			matchWidth = 190,
		},
	},
	defaultRoundPrecision = 0,
}

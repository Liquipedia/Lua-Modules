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
	},
	defaultRoundPrecision = 0,
	match2 = 1,
}

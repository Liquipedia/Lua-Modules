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
	games = {
		hots = {
			abbreviation = 'Heroes',
			name = 'Heroes of the Storm',
			link = 'Heroes of the Storm',
			logo = {
				darkMode = 'Hots logo.png',
				lightMode = 'Hots logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Hots logo.png',
				lightMode = 'Hots logo.png',
			},
		},
	},
	defaultGame = 'hots',
	defaultRoundPrecision = 0,
	defaultTeamLogo = 'Hots logo.png', ---@deprecated
	defaultTeamLogoDark = 'Hots logo.png', ---@deprecated
	match2 = 1,
}

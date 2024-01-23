---
-- @Liquipedia
-- wiki=dota2
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2011,
	wikiName = 'dota2',
	name = 'Dota 2',
	games = {
		dota = {
			abbreviation = 'DotA',
			name = 'Defense of the Ancients',
			link = 'Defense of the Ancients',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Dota2 logo.png',
				lightMode = 'Dota2 logo.png',
			},
		},
		dota2 = {
			abbreviation = 'Dota 2',
			name = 'Dota 2',
			link = 'Dota 2',
			logo = {
				darkMode = 'Dota2 logo.png',
				lightMode = 'Dota2 logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Dota2 logo.png',
				lightMode = 'Dota2 logo.png',
			},
		},
	},
	defaultGame = 'dota2',
	defaultRoundPrecision = 0,
	defaultTeamLogo = 'Dota2 logo.png', ---@deprecated
	defaultTeamLogoDark = 'Dota2 logo.png', ---@deprecated
	match2 = 1,
}

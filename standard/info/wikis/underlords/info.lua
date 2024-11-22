---
-- @Liquipedia
-- wiki=underlords
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2019,
	wikiName = 'underlords',
	name = 'Dota Underlords',
	defaultGame = 'underlords',
	games = {
		underlords = {
			abbreviation = 'Underlords',
			name = 'Dota Underlords',
			link = 'Dota Underlords',
			logo = {
				darkMode = 'Dota Underlords darkmode.png',
				lightMode = 'Dota Underlords lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Dota Underlords darkmode.png',
				lightMode = 'Dota Underlords lightmode.png',
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

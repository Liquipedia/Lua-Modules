---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2015,
	wikiName = 'splatoon',
	name = 'Splatoon',
	games = {
		todo = {
			abbreviation = 'todo',
			name = 'TODO',
			link = 'Main Page',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Splatoon default allmode.png',
				lightMode = 'Splatoon default allmode.png',
			},
		},
	},
	defaultGame = 'todo',
	defaultTeamLogo = 'Splatoon default allmode.png', ---@deprecated
	defaultTeamLogoDark = 'Splatoon default allmode.png', ---@deprecated
}

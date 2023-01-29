---
-- @Liquipedia
-- wiki=fighters
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1996,
	wikiName = 'fighters',
	name = 'Fighting Games',
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
				darkMode = 'Fistlogo std.png',
				lightMode = 'Fistlogo std.png',
			},
		},
	},
	defaultGame = 'todo',
	defaultTeamLogo = 'Fistlogo std.png', ---@deprecated
	defaultTeamLogoDark = 'Fistlogo std.png', ---@deprecated
}

---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2014,
	wikiName = 'hearthstone',
	name = 'Hearthstone',
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
				darkMode = 'Hearthstone logo.png',
				lightMode = 'Hearthstone logo.png',
			},
		},
	},
	defaultGame = 'todo',
	defaultTeamLogo = 'Hearthstone logo.png', ---@deprecated
	defaultTeamLogoDark = 'Hearthstone logo.png', ---@deprecated
}

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
		hs = {
			abbreviation = 'hs',
			name = 'Hearthstone',
			link = 'Hearthstone',
			logo = {
				darkMode = 'Hearthstone logo.png',
				lightMode = 'Hearthstone logo.png',
			},
			defaultTeamLogo = {
				darkMode = 'Hearthstone logo.png',
				lightMode = 'Hearthstone logo.png',
			},
		},
	},
	defaultGame = 'hs',
	defaultTeamLogo = 'Hearthstone logo.png', ---@deprecated
	defaultTeamLogoDark = 'Hearthstone logo.png', ---@deprecated
	match2 = 0,
}

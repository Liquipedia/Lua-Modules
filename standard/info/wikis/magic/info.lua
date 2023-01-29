---
-- @Liquipedia
-- wiki=magic
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1993,
	wikiName = 'magic',
	name = 'Magic: The Gathering',
	games = {
		magic = {
			abbreviation = 'Magic',
			name = 'Magic: The Gathering',
			link = 'Magic: The Gathering',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Liquipedia logo.png',
				lightMode = 'Liquipedia logo.png',
			},
		},
	},
	defaultGame = 'magic',
	defaultTeamLogo = 'Liquipedia logo.png', ---@deprecated
	defaultTeamLogoDark = 'Liquipedia logo.png', ---@deprecated
}

---
-- @Liquipedia
-- wiki=worldofwarcraft
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2007,
	wikiName = 'worldofwarcraft',
	name = 'World of Warcraft',
	games = {
		wow = {
			abbreviation = 'WoW',
			name = 'World of Warcraft',
			link = 'World of Warcraft',
			logo = {
				darkMode = 'WoWlogo Default allmode.png',
				lightMode = 'WoWlogo Default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'WoWlogo Default allmode.png',
				lightMode = 'WoWlogo Default allmode.png',
			},
		},
	},
	defaultGame = 'wow',
	defaultTeamLogo = 'WoWlogo Default allmode.png', ---@deprecated
	defaultTeamLogoDark = 'WoWlogo Default allmode.png', ---@deprecated
	match2 = 0,
}

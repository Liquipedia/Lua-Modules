---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2016,
	wikiName = 'clashroyale',
	name = 'Clash Royale',
	games = {
		cr = {
			abbreviation = 'CR',
			name = 'Clash Royale',
			link = 'Clash Royale',
			logo = {
				darkMode = 'Clash Royale default allmode.png',
				lightMode = 'Clash Royale default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Clash Royale default allmode.png',
				lightMode = 'Clash Royale default allmode.png',
			},
		},
	},
	defaultGame = 'cr',
	defaultTeamLogo = 'Clash Royale.png', ---@deprecated
	defaultTeamLogoDark = 'Clash Royale.png', ---@deprecated
	match2 = 0,
}

---
-- @Liquipedia
-- wiki=osu
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2007,
	wikiName = 'osu',
	name = 'osu!',
	games = {
		osu = {
			abbreviation = 'osu!',
			name = 'osu!',
			link = 'osu!',
			logo = {
				darkMode = 'osu! allmode.png',
				lightMode = 'osu! allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'osu! default allmode.png',
				lightMode = 'osu! default allmode.png',
			},
		},
	},
	defaultGame = 'osu',
	defaultRoundPrecision = 0,
	defaultTeamLogo = 'osu! default allmode.png', ---@deprecated
	defaultTeamLogoDark = 'osu! default allmode.png', ---@deprecated
}

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
			abbreviation = 'osu',
			name = 'osu!',
			link = 'osu!',
			logo = {
				darkMode = 'Osu single color allmode.png',
				lightMode = 'Osu single color allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Osu single color allmode.png',
				lightMode = 'Osu single color allmode.png',
			},
		},
	},
	defaultGame = 'osu',
	defaultRoundPrecision = 0,
	defaultTeamLogo = 'Osu single color allmode.png', ---@deprecated
	defaultTeamLogoDark = 'Osu single color allmode.png', ---@deprecated
}

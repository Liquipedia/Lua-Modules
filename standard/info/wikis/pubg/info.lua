---
-- @Liquipedia
-- wiki=pubg
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2017,
	wikiName = 'pubg',
	name = 'PUBG',
	games = {
		pubg = {
			abbreviation = 'PUBG',
			name = 'PUBG BATTLEGROUNDS',
			link = 'PUBG BATTLEGROUNDS',
			logo = {
				darkMode = 'PUBG BATTLEGROUNDS darkmode.png',
				lightMode = 'PUBG BATTLEGROUNDS lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'PUBG 2021 default allmode.png',
				lightMode = 'PUBG 2021 default allmode.png',
			},
		},
	},
	defaultGame = 'pubg',
	defaultRoundPrecision = 0,
	defaultTeamLogo = 'PUBG Default logo.png', ---@deprecated
	defaultTeamLogoDark = 'PUBG Default logo.png', ---@deprecated
	match2 = 0,
}

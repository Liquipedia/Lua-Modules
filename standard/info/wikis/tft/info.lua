---
-- @Liquipedia
-- wiki=tft
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2019,
	wikiName = 'tft',
	name = 'Teamfight Tactics',
	games = {
		tft = {
			abbreviation = 'TFT',
			name = 'Teamfight Tactics',
			link = 'Teamfight Tactics',
			logo = {
				darkMode = 'Teamfight Tactics LOGO darkmode.png',
				lightMode = 'Teamfight Tactics LOGO lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Teamfight Tactics Double Up darkmode.png',
				lightMode = 'Teamfight Tactics Double Up lightmode.png',
			},
		},
		ffgs = {
			abbreviation = 'FFGS',
			name = 'Fight For the Golden Spatula',
			link = 'Fight For the Golden Spatula',
			logo = {
				darkMode = 'Golden Spatula allmode.png',
				lightMode = 'Golden Spatula allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Golden Spatula allmode.png',
				lightMode = 'Golden Spatula allmode.png',
			},
		},
	},
	defaultGame = 'tft',
	defaultRoundPrecision = 0,
	defaultTeamLogo = 'Teamfight Tactics Double Up lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'Teamfight Tactics Double Up darkmode.png', ---@deprecated
	match2 = 0,
}

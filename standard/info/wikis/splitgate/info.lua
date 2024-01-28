---
-- @Liquipedia
-- wiki=splitgate
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2019,
	wikiName = 'splitgate',
	name = 'Splitgate',
	games = {
		splitgate = {
			abbreviation = 'SG',
			name = 'Splitgate',
			link = 'Splitgate',
			logo = {
				darkMode = 'Splitgate 2021 darkmode.png',
				lightMode = 'Splitgate 2021 lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Splitgate 2021 darkmode.png',
				lightMode = 'Splitgate 2021 lightmode.png',
			},
		},
	},
	defaultGame = 'splitgate',
	defaultRoundPrecision = 0,
	defaultTeamLogo = 'Splitgate allmode.png (2019) Change date '
		.. '(2021-06-01) Splitgate 2021 lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'Splitgate allmode.png (2019) Change date '
		.. '(2021-06-01) Splitgate 2021 darkmode.png', ---@deprecated
	match2 = 2,
}

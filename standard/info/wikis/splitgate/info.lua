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
	defaultGame = 'splitgate',
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
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			status = 2,
		},
	},
	defaultRoundPrecision = 0,
}

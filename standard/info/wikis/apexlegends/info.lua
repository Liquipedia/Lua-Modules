---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2019,
	wikiName = 'apexlegends',
	name = 'Apex Legends',
	defaultGame = 'apexlegends',
	games = {
		apexlegends = {
			abbreviation = 'APEX',
			name = 'Apex Legends',
			link = 'Apex Legends',
			logo = {
				darkMode = 'Apex Legends default darkmode.png',
				lightMode = 'Apex Legends default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Apex Legends default darkmode.png',
				lightMode = 'Apex Legends default lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = true,
			allowManual = true,
		},
		match2 = {
			status = 1,
		},
	},
	defaultRoundPrecision = 0,
}

---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2015,
	wikiName = 'rocketleague',
	name = 'Rocket League',
	games = {
		rl = {
			abbreviation = '',
			name = '',
			link = '',
			logo = {
				darkMode = 'Rocket League default darkmode.png',
				lightMode = 'Rocket League default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Rocket League default darkmode.png',
				lightMode = 'Rocket League default lightmode.png',
			},
		},
		sarpbc = {
			abbreviation = 'SARPBC',
			name = 'Supersonic Acrobatic Rocket-Powered Battle-Cars',
			link = 'Supersonic Acrobatic Rocket-Powered Battle-Cars',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Rocket League default darkmode.png',
				lightMode = 'Rocket League default lightmode.png',
			},
		},
	},
	defaultGame = 'rl',
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = true,
			allowManual = true,
		},
	},
	opponentDisplayLibrary = 'OpponentDisplay/Custom',
	match2 = 2,
}

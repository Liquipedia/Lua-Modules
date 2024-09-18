---
-- @Liquipedia
-- wiki=splatoon
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2015,
	wikiName = 'splatoon',
	name = 'Splatoon',
	defaultGame = '1',
	games = {
		['1'] = {
			abbreviation = 'SP1',
			name = 'Splatoon',
			link = 'Splatoon',
			logo = {
				darkMode = 'Splatoon default darkmode.png',
				lightMode = 'Splatoon default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Splatoon default darkmode.png',
				lightMode = 'Splatoon default lightmode.png',
			},
		},
		['2'] = {
			abbreviation = 'SP2',
			name = 'Splatoon 2',
			link = 'Splatoon 2',
			logo = {
				darkMode = 'Splatoon 2 default allmode.png',
				lightMode = 'Splatoon 2 default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Splatoon 2 default allmode.png',
				lightMode = 'Splatoon 2 default allmode.png',
			},
		},
		['3'] = {
			abbreviation = 'SP3',
			name = 'Splatoon 3',
			link = 'Splatoon 3',
			logo = {
				darkMode = 'Splatoon 3 default allmode.png',
				lightMode = 'Splatoon 3 default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Splatoon 3 default allmode.png',
				lightMode = 'Splatoon 3 default allmode.png',
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
			matchWidthMobile = 110,
			matchWidth = 190,
		},
	},
}

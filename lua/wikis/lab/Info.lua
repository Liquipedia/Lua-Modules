---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1800,
	wikiName = 'lab',
	name = 'Lab',
	defaultGame = 'lab',
	games = {
		lab = {
			abbreviation = 'Lab',
			name = 'Lab',
			link = 'Lab',
			logo = {
				darkMode = 'Halved Shield default darkmode.png',
				lightMode = 'Halved Shield default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Halved Shield default darkmode.png',
				lightMode = 'Halved Shield default lightmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = false,
		},
		match2 = {
			status = 0,
			matchWidth = 180,
		},
	},
}

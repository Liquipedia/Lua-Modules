---
-- @Liquipedia
-- wiki=criticalops
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2015,
	wikiName = 'criticalops',
	name = 'Critical Ops',
	games = {
		cops = {
			abbreviation = 'Crit Ops',
			name = 'Critical Ops',
			link = 'Critical Ops',
			logo = {
				darkMode = 'Critical Ops allmode.png',
				lightMode = 'Critical Ops allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Critical Ops allmode.png',
				lightMode = 'Critical Ops allmode.png',
			},
		},
	},
	defaultGame = 'cops',
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
	},
	match2 = 2,
}

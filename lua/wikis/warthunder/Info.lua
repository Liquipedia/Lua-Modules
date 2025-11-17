---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2012,
	wikiName = 'warthunder',
	name = 'War Thunder',
	defaultGame = 'War Thunder',
	games = {
		warthunder = {
			abbreviation = 'WT',
			name = 'War Thunder',
			link = 'War Thunder',
			logo = {
				darkMode = 'War Thunder default allmode.png',
				lightMode = 'War Thunder default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'War Thunder default allmode.png',
				lightMode = 'War Thunder default allmode.png',
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
			status = 2,
			matchWidth = 180,
		},
	},
	defaultRoundPrecision = 0,
}

---
-- @Liquipedia
-- wiki=geoguessr
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2013,
	wikiName = 'geoguessr',
	name = 'GeoGuessr',
	defaultGame = 'geoguessr',
	games = {
		geoguessr = {
			abbreviation = 'GeoGuessr',
			name = 'GeoGuessr',
			link = 'GeoGuessr',
			logo = {
				darkMode = 'GeoGuessr allmode.png',
				lightMode = 'GeoGuessr allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'GeoGuessr allmode.png',
				lightMode = 'GeoGuessr allmode.png',
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
		},
	},
	defaultRoundPrecision = 0,
}

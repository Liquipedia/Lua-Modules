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
			abbreviation = 'Geo',
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
			allowManual = true,
		},
		match2 = {
			matchWidthMobile = 110,
			matchWidth = 190,
		},
	},
	defaultRoundPrecision = 0,
	match2 = 0,
}

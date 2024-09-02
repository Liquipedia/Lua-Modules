---
-- @Liquipedia
-- wiki=squadrons
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2020,
	wikiName = 'squadrons',
	name = 'Star Wars: Squadrons',
	defaultGame = 'squadrons',
	games = {
		squadrons = {
			abbreviation = 'Squadrons',
			name = 'Star Wars: Squadrons',
			link = 'Star Wars: Squadrons',
			logo = {
				darkMode = 'Star Wars Squadrons allmode.png',
				lightMode = 'Star Wars Squadrons allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Star Wars Squadrons allmode.png',
				lightMode = 'Star Wars Squadrons allmode.png',
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
			status = 0,
		},
	},
}

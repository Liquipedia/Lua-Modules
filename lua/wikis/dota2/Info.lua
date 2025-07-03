---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2011,
	wikiName = 'dota2',
	name = 'Dota 2',
	defaultGame = 'dota2',
	games = {
		dota = {
			abbreviation = 'DotA',
			name = 'Defense of the Ancients',
			link = 'Defense of the Ancients',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Dota 2 default allmode.png',
				lightMode = 'Dota 2 default allmode.png',
			},
		},
		dota2 = {
			abbreviation = 'Dota 2',
			name = 'Dota 2',
			link = 'Dota 2',
			logo = {
				darkMode = 'Dota 2 default allmode.png',
				lightMode = 'Dota 2 default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Dota 2 default allmode.png',
				lightMode = 'Dota 2 default allmode.png',
			},
		},
	},
	config = {
		squads = {
			hasPosition = true,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			matchPage = true,
			status = 2,
			matchWidth = 180,
		},
		ratings = {
			interval = 'weekly',
		},
		thisDay = {
			tiers = {1, 2},
			excludeTierTypes = {'Qualifier'},
			showPatches = true,
		},
	},
	defaultRoundPrecision = 0,
}

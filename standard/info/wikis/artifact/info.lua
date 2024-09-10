---
-- @Liquipedia
-- wiki=artifact
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2018,
	wikiName = 'artifact',
	name = 'Artifact',
	defaultGame = 'artifact',
	games = {
		artifact = {
			abbreviation = 'Artifact',
			name = 'Artifact',
			link = 'Artifact',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'Artifact allmode.png',
				lightMode = 'Artifact allmode.png',
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

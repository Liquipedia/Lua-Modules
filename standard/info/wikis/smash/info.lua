---
-- @Liquipedia
-- wiki=smash
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1999,
	wikiName = 'smash',
	name = 'Smash',
	defaultGame = 'melee',
	games = {
		melee = {
			abbreviation = 'Melee',
			name = 'Super Smash Bros. Melee',
			link = 'Super Smash Bros. Melee',
			logo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
		},
		brawl = {
			abbreviation = 'Brawl',
			name = 'Super Smash Bros. Brawl',
			link = 'Super Smash Bros. Brawl',
			logo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
		},
		wiiu = {
			abbreviation = 'Wii U',
			name = 'Super Smash Bros. for Wii U',
			link = 'Super Smash Bros. for Wii U',
			logo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
		},
		ultimate = {
			abbreviation = 'Ultimate',
			name = 'Super Smash Bros. Ultimate',
			link = 'Super Smash Bros. Ultimate',
			logo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
		},
		pm = {
			abbreviation = 'PM',
			name = 'Project M',
			link = 'Project M',
			logo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
		},
		['64'] = {
			abbreviation = '64',
			name = 'Super Smash Bros.',
			link = 'Super Smash Bros.',
			logo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Smash default darkmode.png',
				lightMode = 'Smash default lightmode.png',
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
	opponentLibrary = 'Opponent/Custom',
}

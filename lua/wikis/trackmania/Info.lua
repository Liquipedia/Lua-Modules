---
-- @Liquipedia
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2006,
	wikiName = 'trackmania',
	name = 'Trackmania',
	defaultGame = 'tm',
	games = {
		tm = {
			abbreviation = 'TM',
			name = 'Trackmania',
			link = 'Trackmania',
			defaultTeamLogo = {
				darkMode = 'TMlogowhite.png',
				lightMode = 'TMlogoblack.png',
			},
			logo = {
				darkMode = 'TMlogowhite.png',
				lightMode = 'TMlogoblack.png',
			},
		},
		tmuf = {
			abbreviation = 'TMUF',
			name = 'TrackMania United Forever',
			link = 'TrackMania United Forever',
			defaultTeamLogo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
			logo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
		},
		tm2s = {
			abbreviation = 'TM2S',
			name = 'TrackMania 2 Stadium',
			link = 'TrackMania 2 Stadium',
			defaultTeamLogo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
			logo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
		},
		tm2c = {
			abbreviation = 'TM2C',
			name = 'TrackMania 2 Canyon',
			link = 'TrackMania 2 Canyon',
			defaultTeamLogo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
			logo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
		},
		tm2v = {
			abbreviation = 'TM2V',
			name = 'TrackMania 2 Valley',
			link = 'TrackMania 2 Valley',
			defaultTeamLogo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
			logo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
		},
		tm2l = {
			abbreviation = 'TM2L',
			name = 'TrackMania 2 Lagoon',
			link = 'TrackMania 2 Lagoon',
			defaultTeamLogo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
			logo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
		},
		tmt = {
			abbreviation = 'TMT',
			name = 'TrackMania Turbo',
			link = 'TrackMania Turbo',
			defaultTeamLogo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
			logo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
		},
		tmn = {
			abbreviation = 'TMN',
			name = 'TrackMania Nations',
			link = 'TrackMania Nations',
			defaultTeamLogo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
			logo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
		},
		tmnf = {
			abbreviation = 'TMNF',
			name = 'TrackMania Nations Forever',
			link = 'TrackMania Nations Forever',
			defaultTeamLogo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
			logo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
		},
		tm2 = {
			abbreviation = 'TM2',
			name = 'TrackMania 2',
			link = 'TrackMania 2',
			defaultTeamLogo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
			logo = {
				darkMode = 'Trackmania logo darkmode.png',
				lightMode = 'Trackmania logo lightmode.png',
			},
		},
	},
	modes = {
		cup = 'Cup',
		knockout = 'Knockout',
		reverse = 'Reverse Cup',
		rounds = 'Rounds',
		teams = 'Teams',
		timeattack = 'Time Attack',
		tmwt = 'TMWT Duos'
	},
	styles = {
		altcar = 'Altcar',
		alt = 'Altcar',
		backwards = 'Backwards',
		bw = 'Backwards',
		bobsleigh = 'Bobsleigh',
		bob = 'Bobsleigh',
		dirt = 'Dirt',
		endurance = 'Endurance',
		fastlearn = 'Fastlearn',
		fullspeed = 'Fullspeed',
		fs = 'Fullspeed',
		ice = 'Ice',
		kacky = 'Kacky',
		lol = 'LOL',
		mapping = 'Mapping',
		mixed = 'Mixed',
		mix = 'Mixed',
		nascar = 'Nascar',
		pathfinding = 'Pathfinding',
		rpg = 'RPG',
		tech = 'Tech',
		trial = 'Trial',
		zrt = 'ZrT'
	},
	config = {
		squads = {
			hasPosition = false,
			hasSpecialTeam = false,
			allowManual = true,
		},
		match2 = {
			status = 1,
			sortCasters = true,
		},
		infoboxPlayer = {
			automatedHistory = {
				storeFromWikiCode = true,
			},
		},
		standings = {
			alwaysShowStats = {
				swiss = {'matchdiff', 'gamediff'},
			},
		},
		defaultMaxPlayersPerPlacement = 20,
	},
}

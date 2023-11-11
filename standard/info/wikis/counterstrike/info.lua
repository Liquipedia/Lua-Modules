---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local infoData = {
	startYear = 2000,
	wikiName = 'counterstrike',
	name = 'Counter-Strike',
	games = {
		cs1 = {
			order = 1,
			abbreviation = 'CS1',
			name = 'Counter-Strike',
			link = 'Counter-Strike',
			logo = {
				darkMode = 'Cs small.png',
				lightMode = 'Cs small.png',
			},
			defaultTeamLogo = {
				darkMode = 'CS default darkmode.png',
				lightMode = 'CS default lightmode.png',
			},
		},
		cscz = {
			order = 2,
			abbreviation = 'CS:CZ',
			name = 'Condition Zero',
			link = 'Counter-Strike: Condition Zero',
			logo = {
				darkMode = 'Cscz small.png',
				lightMode = 'Cscz small.png',
			},
			defaultTeamLogo = {
				darkMode = 'CS default darkmode.png',
				lightMode = 'CS default lightmode.png',
			},
		},
		css = {
			order = 3,
			abbreviation = 'CS:S',
			name = 'Source',
			link = 'Counter-Strike: Source',
			logo = {
				darkMode = 'Css small.png',
				lightMode = 'Css small.png',
			},
			defaultTeamLogo = {
				darkMode = 'CS default darkmode.png',
				lightMode = 'CS default lightmode.png',
			},
		},
		cso = {
			order = 4,
			abbreviation = 'CSO',
			name = 'Counter-Strike Online',
			link = 'Counter-Strike Online',
			logo = {
				darkMode = 'CS Online icon.png',
				lightMode = 'CS Online icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'CS default darkmode.png',
				lightMode = 'CS default lightmode.png',
			},
		},
		csgo = {
			order = 5,
			abbreviation = 'CS:GO',
			name = 'Global Offensive',
			link = 'Counter-Strike: Global Offensive',
			logo = {
				darkMode = 'CSGO gameicon allmode.png',
				lightMode = 'CSGO gameicon allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'CSGO default darkmode.png',
				lightMode = 'CSGO default lightmode.png',
			},
		},
		csgocs2 = {
			order = 6,
			abbreviation = 'CS:GO/CS2',
			name = 'CS:GO / CS2',
			link = 'Counter-Strike 2',
			logo = {
				darkMode = 'CSGO-CS2 gameicon allmode.png',
				lightMode = 'CSGO-CS2 gameicon allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Counter-Strike 2 default darkmode.png',
				lightMode = 'Counter-Strike 2 default lightmode.png',
			},
		},
		cs2 = {
			order = 7,
			abbreviation = 'CS2',
			name = 'Counter-Strike 2',
			link = 'Counter-Strike 2',
			logo = {
				darkMode = 'Counter-Strike 2 gameicon allmode.png',
				lightMode = 'Counter-Strike 2 gameicon allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Counter-Strike 2 default darkmode.png',
				lightMode = 'Counter-Strike 2 default lightmode.png',
			},
		},
	},
	defaultGame = 'csgo',
	defaultTeamLogo = {
		csgo = 'CSGO default lightmode.png',
		cso = 'CS Online default lightmode.png',
		css = 'CS default lightmode.png',
		cs1 = 'CS default lightmode.png',
		cs16 = 'CS default lightmode.png',
		cscz = 'CS default lightmode.png',
		cs2 = 'Counter-Strike 2 default lightmode.png',
	}, ---@deprecated
	defaultTeamLogoDark = {
		csgo = 'CSGO default darkmode.png',
		cso = 'CS Online default lightmode.png',
		css = 'CS default darkmode.png',
		cs1 = 'CS default lightmode.png',
		cs16 = 'CS default darkmode.png',
		cscz = 'CS default darkmode.png',
		cs2 = 'Counter-Strike 2 default lightmode.png',
	}, ---@deprecated
}

infoData.games.cs16 = infoData.games.cs1
infoData.games.cs = infoData.games.cs1

return infoData

---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2000,
	wikiName = 'counterstrike',
	name = 'Counter-Strike',
	games = {
		cs16 = {
			abbreviation = 'CS',
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
		css = {
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
		cscz = {
			abbreviation = 'CS:CZ',
			name = 'Condition Zero',
			link = 'Counter-Strike: Condition Zero',
			logo = {
				darkMode = 'Cszo small.png',
				lightMode = 'Cszo small.png',
			},
			defaultTeamLogo = {
				darkMode = 'CS default darkmode.png',
				lightMode = 'CS default lightmode.png',
			},
		},
		cso = {
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
			abbreviation = 'CS:GO',
			name = 'Global Offensive',
			link = 'Counter-Strike: Global Offensive',
			logo = {
				darkMode = 'csgo icon.png',
				lightMode = 'csgo icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'CSGO default darkmode.png',
				lightMode = 'CSGO default lightmode.png',
			},
		},
		cs2 = {
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
		cs16 = 'CS default lightmode.png',
		cscz = 'CS default lightmode.png',
		cs2 = 'Counter-Strike 2 default lightmode.png',
	}, ---@deprecated
	defaultTeamLogoDark = {
		csgo = 'CSGO default darkmode.png',
		cso = 'CS Online default lightmode.png',
		css = 'CS default darkmode.png',
		cs16 = 'CS default darkmode.png',
		cscz = 'CS default darkmode.png',
		cs2 = 'Counter-Strike 2 default lightmode.png',
	}, ---@deprecated
}

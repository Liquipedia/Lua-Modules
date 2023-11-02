---
-- @Liquipedia
-- wiki=arenaofvalor
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2015,
	wikiName = 'arenaofvalor',
	name = 'Arena of Valor',

	games = {
		aov = {
			abbreviation = 'AoV',
			name = 'Arena of Valor',
			link = 'Arena of Valor',
			logo = {
				darkMode = 'Arena of Valor Icon.png',
				lightMode = 'Arena of Valor Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Arena of ValorLogo.png',
				lightMode = 'Arena of ValorLogo.png',
			},
		},
		aovas = {
			abbreviation = 'AoV/HoK ASIAD',
			name = 'Honor of Kings (Asian Games Version)',
			link = 'Honor of Kings (Asian Games Version)',
			logo = {
				darkMode = 'Honor of Kings Icon.png',
				lightMode = 'Honor of Kings Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Honor of Kings 2018-12-24 Logo.png',
				lightMode = 'Honor of Kings 2018-12-24 Logo.png',
			},
		},
		hok = {
			abbreviation = 'HoK',
			name = 'Honor of Kings',
			link = 'Honor of Kings',
			logo = {
				darkMode = 'Honor of Kings Icon.png',
				lightMode = 'Honor of Kings Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Honor of Kings 2018-12-24 Logo.png',
				lightMode = 'Honor of Kings 2018-12-24 Logo.png',
			},
		},
		hokic = {
			abbreviation = 'HoK KIC',
			name = 'Honor of Kings (KIC Version)',
			link = 'Honor of Kings (KIC Version)',
			logo = {
				darkMode = 'Honor of Kings Icon.png',
				lightMode = 'Honor of Kings Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Honor of Kings 2018-12-24 Logo.png',
				lightMode = 'Honor of Kings 2018-12-24 Logo.png',
			},
		},
	},
	defaultGame = 'aov',

	defaultTeamLogo = {
		aov = 'Arena of ValorLogo.png', --Arena of Valor
		hok = 'Honor of Kings 2018-12-24 Logo.png', --Honor of Kings
	}, ---@deprecated
	defaultTeamLogoDark = {
		aov = 'Arena of ValorLogo.png', --Arena of Valor
		hok = 'Honor of Kings 2018-12-24 Logo.png', --Honor of Kings
	}, ---@deprecated
}

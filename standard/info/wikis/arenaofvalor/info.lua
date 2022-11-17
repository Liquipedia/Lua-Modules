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
			logo = {
				darkMode = 'Arena of Valor Icon.png',
				lightMode = 'Arena of Valor Icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Arena of ValorLogo.png',
				lightMode = 'Arena of ValorLogo.png',
			},
		},
		hok = {
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

---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2006, --vegas from 2006; vegas2 from 2008; siege from 2015
	wikiName = 'rainbowsix',
	name = 'Rainbow Six',
	games = {
		siege = {
			logo = {
				darkMode = 'R6S icon.png',
				lightMode = 'R6S icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Rainbow Six Siege Logo darkmode.png',
				lightMode = 'Rainbow Six Siege Logo lightmode.png',
			},
		},
		vegas2 = {
			logo = {
				darkMode = 'R6_Vegas_2_icon.png',
				lightMode = 'R6_Vegas_2_icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Rainbow Six Vegas Logo darkmode.png',
				lightMode = 'Rainbow Six Vegas Logo lightmode.png',
			},
		},
	},
	defaultGame = 'siege',

	defaultTeamLogo = {
		siege = 'Rainbow Six Siege Logo lightmode.png',
		vegas2 = 'Rainbow Six Vegas Logo lightmode.png',
	}, ---@deprecated
	defaultTeamLogoDark = {
		siege = 'Rainbow Six Siege Logo darkmode.png',
		vegas2 = 'Rainbow Six Vegas Logo darkmode.png',
	}, ---@deprecated
}

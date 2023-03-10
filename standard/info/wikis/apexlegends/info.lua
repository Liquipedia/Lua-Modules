---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2019,
	wikiName = 'apexlegends',
	name = 'Apex Legends',
	games = {
		apexlegends = {
			abbreviation = 'APEX',
			name = 'Apex Legends',
			link = 'Apex Legends',
			logo = {
				darkMode = 'Apex Legends default lightmode.png',
				lightMode = 'Apex Legends default darkmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Apex Legends gameicon lightmode.png',
				lightMode = 'Apex Legends gameicon darkmode.png',
			},
		},
	},
	defaultGame = 'apexlegends',
	defaultTeamLogo = 'Apex Legends gameicon lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'Apex Legends gameicon darkmode.png', ---@deprecated
}

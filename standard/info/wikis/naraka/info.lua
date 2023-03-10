---
-- @Liquipedia
-- wiki=naraka
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 2021,
	wikiName = 'naraka',
	name = 'Naraka: Bladepoint',
	games = {
		naraka = {
			abbreviation = 'Naraka',
			name = 'Naraka: Bladepoint',
			link = 'Naraka: Bladepoint',
			logo = {
				darkMode = 'Logo filler event.png',
				lightMode = 'Logo filler event.png',
			},
			defaultTeamLogo = {
				darkMode = 'NARAKA darkmode.png',
				lightMode = 'NARAKA lightmode.png',
			},
		},
	},
	defaultGame = 'naraka',
	defaultTeamLogo = 'NARAKA lightmode.png', ---@deprecated
	defaultTeamLogoDark = 'NARAKA darkmode.png', ---@deprecated
}

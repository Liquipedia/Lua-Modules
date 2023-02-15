---
-- @Liquipedia
-- wiki=fighters
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1996,
	wikiName = 'fighters',
	name = 'Fighting Games',
	games = {
		fighters = {
			abbreviation = 'Fighters',
			name = 'Fighters',
			link = 'Fighters',
			logo = {
				darkMode = 'Fistlogo std.png', --not dark mode friendly
				lightMode = 'Fistlogo std.png',
			},
			defaultTeamLogo = {
				darkMode = 'Fistlogo std.png', --not dark mode friendly
				lightMode = 'Fistlogo std.png',
			},
		},
	},
	defaultGame = 'fighters',
	defaultTeamLogo = 'Fistlogo std.png', ---@deprecated
	defaultTeamLogoDark = 'Fistlogo std.png', ---@deprecated
}

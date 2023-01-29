---
-- @Liquipedia
-- wiki=tetris
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = '1984',
	wikiName = 'tetris',
	name = 'Tetris',
	games = {
		tetris = {
			abbreviation = 'Tetris',
			name = 'Tetris',
			link = 'tetris:Main Page',
			logo = {
				darkMode = 'Tetris default allmode.png',
				lightMode = 'Tetris default allmode.png',
			},
			defaultTeamLogo = {
				darkMode = 'Tetris default allmode.png',
				lightMode = 'Tetris default allmode.png',
			},
		},
	},
	defaultGame = 'tetris',

	defaultTeamLogo = 'Tetris default allmode.png', ---@deprecated
	defaultTeamLogoDark = 'Tetris default allmode.png', ---@deprecated
}

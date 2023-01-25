---
-- @Liquipedia
-- wiki=arenafps
-- page=Module:Info
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

return {
	startYear = 1995,
	wikiName = 'arenafps',
	name = 'Arena FPS',
	games = {
		qc = {
			logo = {
				darkMode = 'Quake Champions icon.png',
				lightMode = 'Quake Champions icon.png',
			},
			defaultTeamLogo = {
				darkMode = 'Quake logo.png',
				lightMode = 'Quake logo.png',
			},
		},
		-- TODO: https://liquipedia.net/arenafps/Special:PrefixIndex?prefix=Game%2F&namespace=10
	},
	defaultGame = 'qc',
	defaultTeamLogo = 'Quake logo.png', ---@deprecated
	defaultTeamLogoDark = 'Quake logo.png', ---@deprecated
}

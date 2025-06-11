---
-- @Liquipedia
-- page=Module:Faction/Data
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Info = require('Module:Info')

return {
	defaultGame = Info.defaultGame,
	factionProps = {[Info.defaultGame] = {}},
	defaultFaction = '',
	factions = {
		[Info.defaultGame] = {},
	},
	knownFactions = {},
	coreFactions = {},
	aliases = {[Info.defaultGame] = {}},
}

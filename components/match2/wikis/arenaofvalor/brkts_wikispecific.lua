---
-- @Liquipedia
-- wiki=arenaofvalor
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local _EPOCH_TIME_EXTENDED = '0000-01-01T00:00:00+00:00'

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base'))

--
-- Override functons
--
function WikiSpecific.matchHasDetails(match)
	return match.dateIsExact
		or match.date ~= _EPOCH_TIME_EXTENDED
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or 0 < #match.games
end

WikiSpecific.defaultIcon = 'Arena of Valor allmode.png'

return WikiSpecific

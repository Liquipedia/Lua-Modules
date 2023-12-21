---
-- @Liquipedia
-- wiki=crossfire
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base', {requireDevIfEnabled = true}))

function WikiSpecific.matchHasDetails(match)
	return match.dateIsExact
		or match.date ~= _EPOCH_TIME_EXTENDED
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or 0 < #match.games
end

return WikiSpecific

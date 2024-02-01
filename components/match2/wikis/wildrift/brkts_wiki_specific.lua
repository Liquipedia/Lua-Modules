---
-- @Liquipedia
-- wiki=wildrift
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base'))

--
-- Override functons
--
function WikiSpecific.matchHasDetails(match)
	return match.dateIsExact
		or match.date ~= DateExt.defaultDateTimeExtended
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or 0 < #match.games
end

WikiSpecific.defaultIcon = 'Wild_Rift_Teamcard.png'

return WikiSpecific

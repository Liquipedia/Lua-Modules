---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base'))

---@diagnostic disable-next-line: duplicate-set-field
function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return Lua.import('Module:MatchGroup/Display/Horizontallist').BracketContainer
end

return WikiSpecific

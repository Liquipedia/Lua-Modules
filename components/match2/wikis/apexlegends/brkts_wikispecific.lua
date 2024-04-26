---
-- @Liquipedia
-- wiki=apexlegends
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class ApexlegendsBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return Lua.import('Module:MatchGroup/Display/Horizontallist').BracketContainer
end

return WikiSpecific

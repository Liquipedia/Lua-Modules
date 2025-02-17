---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')


local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class LeagueoflegendsBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

---@param match table
---@return boolean
function WikiSpecific.matchHasDetails(match)
	local MatchGroupDisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
	local MatchPage = Lua.import('Module:MatchPage')
	return MatchGroupDisplayHelper.defaultMatchHasDetails(match) or
		MatchPage.isEnabledFor(match)
end

return WikiSpecific

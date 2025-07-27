---
-- @Liquipedia
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class RocketleagueBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

---@param matchGroupType string
---@param maxOpponentCount integer
---@return function
function WikiSpecific.getMatchGroupContainer(matchGroupType, maxOpponentCount)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist').MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Custom').BracketContainer
end

return WikiSpecific

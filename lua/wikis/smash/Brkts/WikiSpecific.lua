---
-- @Liquipedia
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class SmashBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

---@param matchGroupType string
---@param maxOpponentCount integer
---@return function
function WikiSpecific.getMatchGroupContainer(matchGroupType, maxOpponentCount)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist').MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Custom').BracketContainer
end

---@param match table
---@return boolean
function WikiSpecific.matchHasDetails(match)
	return match.dateIsExact
		or Logic.isNotEmpty(match.vod)
		or not Table.isEmpty(match.links)
		or Logic.isNotEmpty(match.comment)
		or 0 < #match.games
end

return WikiSpecific

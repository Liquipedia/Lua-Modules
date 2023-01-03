---
-- @Liquipedia
-- wiki=clashroyale
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base', {requireDevIfEnabled = true}))

function WikiSpecific.matchHasDetails(match)
	return match.dateIsExact
		or match.timestamp ~= DateExt.epochZero
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or 0 < #match.games
end

function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true}).MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Custom', {requireDevIfEnabled = true}).BracketContainer
end

return WikiSpecific

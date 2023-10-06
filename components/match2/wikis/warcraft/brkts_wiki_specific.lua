---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WikiSpecific = Table.copy(require('Module:Brkts/WikiSpecific/Base'))

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	local CustomMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom', {requireDevIfEnabled = true})
	return CustomMatchGroupUtil.matchFromRecord
end)

---@param matchGroupType string
---@return Html
---@diagnostic disable-next-line: duplicate-set-field
function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true}).MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Custom', {requireDevIfEnabled = true}).BracketContainer
end

WikiSpecific.processMap = FnUtil.identity
WikiSpecific.processPlayer = FnUtil.identity

---Determine if a match has details that should be displayed via popup
---@param match table
---@return boolean
function WikiSpecific.matchHasDetails(match)
	return match.dateIsExact
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or match.casters
		or 0 < #match.vetoes
		or Array.any(match.games, function(game)
			return game.map and game.map ~= 'TBD'
				or game.winner
		end)
end

return WikiSpecific

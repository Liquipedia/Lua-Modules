---
-- @Liquipedia
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FnUtil = Lua.import('Module:FnUtil')
local Table = Lua.import('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class StarcraftBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
	return StarcraftMatchGroupUtil.matchFromRecord
end)

WikiSpecific.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Starcraft')
	return InputModule.processMatch
end)

---@param matchGroupType string
---@param maxOpponentCount integer
---@return function
function WikiSpecific.getMatchGroupContainer(matchGroupType, maxOpponentCount)
	if maxOpponentCount > 2 then
		local Horizontallist = Lua.import('Module:MatchGroup/Display/Horizontallist')
		return Horizontallist.BracketContainer
	elseif matchGroupType == 'matchlist' then
		local MatchList = Lua.import('Module:MatchGroup/Display/Matchlist')
		return WikiSpecific.adjustMatchGroupContainerConfig(MatchList.MatchlistContainer)
	end

	local Bracket = Lua.import('Module:MatchGroup/Display/Bracket')
	return WikiSpecific.adjustMatchGroupContainerConfig(Bracket.BracketContainer)
end

---@param displayContainer function
---@return function
function WikiSpecific.adjustMatchGroupContainerConfig(displayContainer)
	local StarcraftMatchSummary = Lua.import('Module:MatchSummary/Starcraft')
	return function(props, matches)
		local config = Table.merge(props.config, {MatchSummaryContainer = StarcraftMatchSummary.getByMatchId})
		return displayContainer(Table.merge(props, {config = config}), matches)
	end
end

---@param displayMode string
---@return function?
function WikiSpecific.getMatchContainer(displayMode)
	if displayMode == 'singleMatch' then
		-- Single match, displayed flat on a page (no popup)
		local SingleMatch = Lua.import('Module:MatchGroup/Display/SingleMatch')
		return WikiSpecific.adjustMatchGroupContainerConfig(SingleMatch.SingleMatchContainer)
	end
end

WikiSpecific.matchHasDetails = FnUtil.lazilyDefineFunction(function()
	local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
	return StarcraftMatchGroupUtil.matchHasDetails
end)

return WikiSpecific

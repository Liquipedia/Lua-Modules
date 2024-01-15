---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class StormgateBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft')
	return StarcraftMatchGroupUtil.matchFromRecord
end)

WikiSpecific.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Starcraft')
	return InputModule.processMatch
end)

---@param matchGroupType string
---@return function
function WikiSpecific.getMatchGroupContainer(matchGroupType)
	if matchGroupType == 'matchlist' then
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
		local config = Table.merge(props.config, {MatchSummaryContainer = StarcraftMatchSummary.MatchSummaryContainer})
		return displayContainer(Table.merge(props, {config = config}), matches)
	end
end

---@param displayMode string
---@return function?
function WikiSpecific.getMatchContainer(displayMode)
	if displayMode == 'singleMatch' then
		-- Single match, displayed flat on a page (no popup)
		local SingleMatch = Lua.import('Module:MatchGroup/Display/SingleMatch/Starcraft')
		return SingleMatch.SingleMatchContainer
	end
end

WikiSpecific.matchHasDetails = FnUtil.lazilyDefineFunction(function()
	local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft')
	return StarcraftMatchGroupUtil.matchHasDetails
end)

-- useless functions that should be present for some default checks
-- would get called from Module:Match/Subobjects if we wouldn't circumvent that module completly
WikiSpecific.processMap = FnUtil.identity

return WikiSpecific

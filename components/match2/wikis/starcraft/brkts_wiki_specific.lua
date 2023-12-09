---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base', {requireDevIfEnabled = true})

---@class StarcraftBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft', {requireDevIfEnabled = true})
	return StarcraftMatchGroupUtil.matchFromRecord
end)

WikiSpecific.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Starcraft', {requireDevIfEnabled = true})
	return InputModule.processMatch
end)

function WikiSpecific.getMatchGroupContainer(matchGroupType)
	if matchGroupType == 'matchlist' then
		local MatchList = Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true})
		return WikiSpecific.adjustMatchGroupContainerConfig(MatchList.MatchlistContainer)
	end

	local Bracket = Lua.import('Module:MatchGroup/Display/Bracket', {requireDevIfEnabled = true})
	return WikiSpecific.adjustMatchGroupContainerConfig(Bracket.BracketContainer)
end

function WikiSpecific.adjustMatchGroupContainerConfig(displayContainer)
	local StarcraftMatchSummary = Lua.import('Module:MatchSummary/Starcraft', {requireDevIfEnabled = true})
	return function(props, matches)
		local config = Table.merge(props.config, {MatchSummaryContainer = StarcraftMatchSummary.MatchSummaryContainer})
		return displayContainer(Table.merge(props, {config = config}), matches)
	end
end

function WikiSpecific.getMatchContainer(displayMode)
	if displayMode == 'singleMatch' then
		-- Single match, displayed flat on a page (no popup)
		local SingleMatch = Lua.import(
			'Module:MatchGroup/Display/SingleMatch/Starcraft',
			{requireDevIfEnabled = true}
		)
		return SingleMatch.SingleMatchContainer
	end
end

WikiSpecific.matchHasDetails = FnUtil.lazilyDefineFunction(function()
	local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft', {requireDevIfEnabled = true})
	return StarcraftMatchGroupUtil.matchHasDetails
end)

-- useless functions that should be present for some default checks
-- would get called from Module:Match/Subobjects if we wouldn't circumvent that module completly
WikiSpecific.processMap = FnUtil.identity

return WikiSpecific

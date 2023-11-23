---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base', {requireDevIfEnabled = true})

---@class Starcraft2BrktsWikiSpecific: BrktsWikiSpecific
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
		local MatchList = Lua.import('Module:MatchGroup/Display/Matchlist/Starcraft', {requireDevIfEnabled = true})
		return MatchList.MatchlistContainer
	end

	local Bracket = Lua.import('Module:MatchGroup/Display/Bracket/Starcraft', {requireDevIfEnabled = true})
	return Bracket.BracketContainer
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

--Default Logo for Teams without Team Template
WikiSpecific.defaultIcon = 'StarCraft 2 Default logo.png'

-- useless functions that should be present for some default checks
-- would get called from Module:Match/Subobjects if we wouldn't circumvent that module completly
WikiSpecific.processMap = FnUtil.identity

return WikiSpecific

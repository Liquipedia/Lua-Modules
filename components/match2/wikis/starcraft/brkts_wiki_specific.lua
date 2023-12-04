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

---@class StarcraftBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base', {requireDevIfEnabled = true}))

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft', {requireDevIfEnabled = true})
	return StarcraftMatchGroupUtil.matchFromRecord
end)

WikiSpecific.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Starcraft', {requireDevIfEnabled = true})
	return InputModule.processMatch
end)

---@diagnostic disable-next-line: duplicate-set-field
function WikiSpecific.getMatchGroupContainer(matchGroupType)
	if matchGroupType == 'matchlist' then
		return Lua.import('Module:MatchGroup/Display/Matchlist/Starcraft', {requireDevIfEnabled = true}).MatchlistContainer
	end
	return Lua.import('Module:MatchGroup/Display/Bracket/Starcraft', {requireDevIfEnabled = true}).BracketContainer
end

---@diagnostic disable-next-line: duplicate-set-field
function WikiSpecific.getMatchContainer(displayMode)
	if displayMode == 'singleMatch' then
		-- Single match, displayed flat on a page (no popup)
		return Lua.import(
			'Module:MatchGroup/Display/SingleMatch/Starcraft',
			{requireDevIfEnabled = true}
		).SingleMatchContainer
	end
end

WikiSpecific.matchHasDetails = FnUtil.lazilyDefineFunction(function()
	local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft', {requireDevIfEnabled = true})
	return StarcraftMatchGroupUtil.matchHasDetails
end)

--Default Logo for Teams without Team Template
WikiSpecific.defaultIcon = 'StarCraft default allmode.png'

-- useless functions that should be present for some default checks
-- would get called from Module:Match/Subobjects if we wouldn't circumvent that module completly
WikiSpecific.processMap = FnUtil.identity

return WikiSpecific

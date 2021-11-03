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

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base', {requireDevIfEnabled = true}))

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	local StarcraftMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Starcraft', {requireDevIfEnabled = true})
	return StarcraftMatchGroupUtil.matchFromRecord
end)

WikiSpecific.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Starcraft', {requireDevIfEnabled = true})
	return InputModule.processMatch
end)

function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist/Starcraft', {requireDevIfEnabled = true}).MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Starcraft', {requireDevIfEnabled = true}).BracketContainer
end

function WikiSpecific.getMatchContainer(displayMode)
	if displayMode == 'singleMatch' then
		-- Single match, displayed flat on a page (no popup)
		return Lua.import(
			'Module:MatchGroup/Display/SingleMatch/Starcraft',
			{requireDevIfEnabled = true}
		).SingleMatchContainer
	end
end

--Default Logo for Teams without Team Template
WikiSpecific.defaultIcon = 'StarCraft default allmode.png'

-- useless functions that should be present for some default checks
-- would get called from Module:Match/Subobjects if we wouldn't circumvent that module completly
function WikiSpecific.processMap(frame, map)
	return map
end

return WikiSpecific

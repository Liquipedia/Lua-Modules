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

local WikiSpecific = Table.copy(require('Module:Brkts/WikiSpecific/Base'))

WikiSpecific.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Starcraft', {requireDevIfEnabled = true})
	return InputModule.processMatch
end)

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	return require('Module:MatchGroup/Util/Starcraft').matchFromRecord
end)

function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist/Starcraft', {requireDevIfEnabled = true}).MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Starcraft', {requireDevIfEnabled = true}).BracketContainer
end

--Default Logo for Teams without Team Template
WikiSpecific.defaultIcon = 'StarCraft 2 Default logo.png'

-- useless functions that should be present for some default checks
-- would get called from Module:Match/Subobjects if we wouldn't circumvent that module completly
function WikiSpecific.processMap(frame, map)
	return map
end

function WikiSpecific.processOpponent(frame, opponent)
	return opponent
end

return WikiSpecific

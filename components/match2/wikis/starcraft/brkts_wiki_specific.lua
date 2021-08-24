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

local WikiSpecific = Table.copy(require('Module:Brkts/WikiSpecific/Base'))

WikiSpecific.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = require('Module:DevFlags').matchGroupDev
		and Lua.requireIfExists('Module:MatchGroup/Input/StarCraft/dev')
		or require('Module:MatchGroup/Input/StarCraft')
	return InputModule.processMatch
end)

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	return require('Module:MatchGroup/Util/Starcraft').matchFromRecord
end)

function WikiSpecific.getMatchGroupModule(matchGroupType)
	local DevFlags = require('Module:DevFlags')
	if matchGroupType == 'matchlist' then
		return DevFlags.matchGroupDev
			and Lua.requireIfExists('Module:MatchGroup/Display/Matchlist/Starcraft/dev')
			or require('Module:MatchGroup/Display/Matchlist/Starcraft')
	else -- matchGroupType == 'bracket'
		return DevFlags.matchGroupDev
			and Lua.requireIfExists('Module:MatchGroup/Display/Bracket/Starcraft/dev')
			or require('Module:MatchGroup/Display/Bracket/Starcraft')
	end
end

--Default Logo for Teams without Team Template
WikiSpecific.defaultIcon = 'StarCraft default allmode.png'

-- useless functions that should be present for some default checks
-- would get called from Module:Match/Subobjects if we wouldn't circumvent that module completly
function WikiSpecific.processMap(frame, map)
	return map
end

function WikiSpecific.processOpponent(frame, opponent)
	return opponent
end

return WikiSpecific

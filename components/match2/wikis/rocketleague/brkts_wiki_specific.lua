---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WikiSpecific = Table.copy(require('Module:Brkts/WikiSpecific/Base'))

WikiSpecific.processMatch = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
	return InputModule.processMatch
end)

WikiSpecific.processMap = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
	return InputModule.processMap
end)

WikiSpecific.processOpponent = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
	return InputModule.processOpponent
end)

WikiSpecific.processPlayer = FnUtil.lazilyDefineFunction(function()
	local InputModule = Lua.import('Module:MatchGroup/Input/Custom', {requireDevIfEnabled = true})
	return InputModule.processPlayer
end)

function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true}).MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Custom', {requireDevIfEnabled = true}).BracketContainer
end

return WikiSpecific

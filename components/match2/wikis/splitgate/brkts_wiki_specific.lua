---
-- @Liquipedia
-- wiki=splitgate
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local _EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'

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

--
-- Override functons
--
function WikiSpecific.matchHasDetails(match)
	return match.dateIsExact
		or match.date ~= _EPOCH_TIME_EXTENDED
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or 0 < #match.games
end

return WikiSpecific

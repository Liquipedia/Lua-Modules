---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local Table = require('Module:Table')
local FnUtil = require('Module:FnUtil')

local WikiSpecific = Table.copy(Lua.import('Module:Brkts/WikiSpecific/Base', {requireDevIfEnabled = true}))

function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true}).MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Custom', {requireDevIfEnabled = true}).BracketContainer
end

WikiSpecific.defaultIcon = 'Rllogo_std.png'

-- Overwrite default matchFromRecord function to pass bestof value along
WikiSpecific.baseMatchFromRecord = FnUtil.lazilyDefineFunction(function()
	return Lua.import('Module:MatchGroup/Util', {requireDevIfEnabled = true}).matchFromRecord
end)

function WikiSpecific.matchFromRecord(record)
	local match = WikiSpecific.baseMatchFromRecord(record)
	match.bestof = record.bestof

	return match
end

return WikiSpecific

---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local WikiSpecific = Table.copy(require('Module:Brkts/WikiSpecific/Base'))

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	local CustomMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom', {requireDevIfEnabled = true})
	return CustomMatchGroupUtil.matchFromRecord
end)

---@param matchGroupType string
---@return Html
---@diagnostic disable-next-line: duplicate-set-field
function WikiSpecific.getMatchGroupContainer(matchGroupType)
	return matchGroupType == 'matchlist'
		and Lua.import('Module:MatchGroup/Display/Matchlist', {requireDevIfEnabled = true}).MatchlistContainer
		or Lua.import('Module:MatchGroup/Display/Bracket/Custom', {requireDevIfEnabled = true}).BracketContainer
end

WikiSpecific.processMap = FnUtil.identity
WikiSpecific.processPlayer = FnUtil.identity

return WikiSpecific

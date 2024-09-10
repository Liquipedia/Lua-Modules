---
-- @Liquipedia
-- wiki=stormgate
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class StormgateBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	local CustomMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
	return CustomMatchGroupUtil.matchFromRecord
end)

WikiSpecific.processMap = FnUtil.identity

---Determine if a match has details that should be displayed via popup
---@param match table
---@return boolean
function WikiSpecific.matchHasDetails(match)
	return match.dateIsExact
		or match.vod
		or not Table.isEmpty(match.links)
		or match.comment
		or match.casters
		or 0 < #match.vetoes
		or Array.any(match.games, function(game)
			return game.map and game.map ~= 'TBD'
				or game.winner
		end)
end

return WikiSpecific

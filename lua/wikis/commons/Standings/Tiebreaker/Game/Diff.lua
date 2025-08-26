---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/Diff
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerGameDiff : StandingsTiebreaker
local TiebreakerGameDiff = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameDiff:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	return games.w - games.l
end

---@return string
function TiebreakerGameDiff:headerTitle()
	return 'Games'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerGameDiff:display(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	return games.w .. ' - ' .. games.l
end

return TiebreakerGameDiff

---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/Game/WinRate
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local TiebreakerGameUtil = Lua.import('Module:Standings/Tiebreaker/Game/Util')
local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerGameWinRate : StandingsTiebreaker
local TiebreakerGameWinRate = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerGameWinRate:valueOf(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	return games.games == 0 and 0.5 or (games.w / games.games)
end

---@return string
function TiebreakerGameWinRate:headerTitle()
	return 'Game Win %'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string
function TiebreakerGameWinRate:display(state, opponent)
	local games = TiebreakerGameUtil.getGames(opponent)
	if games == 0 then
		return '-'
	end
	return string.format('%.2f', MathUtil.round(self:valueOf(state, opponent) * 100, 2)) .. '%'
end

return TiebreakerGameWinRate

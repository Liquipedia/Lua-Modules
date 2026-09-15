---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/StartingPoints
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerInterface = Lua.import('Module:Standings/Tiebreaker/Interface')

---@class TiebreakerStartingPoints : StandingsTiebreaker
local TiebreakerStartingPoints = Class.new(TiebreakerInterface)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return integer
function TiebreakerStartingPoints:valueOf(state, opponent)
	return opponent.startingPoints or 0
end

---@return string
function TiebreakerStartingPoints:headerTitle()
	return 'Start Pts'
end

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return string|number
function TiebreakerStartingPoints:display(state, opponent)
	return opponent.startingPoints or '-'
end

return TiebreakerStartingPoints

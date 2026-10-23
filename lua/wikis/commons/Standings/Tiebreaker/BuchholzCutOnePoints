---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/BuchholzCutOnePoints
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerBuchholzCutOne = Lua.import('Module:Standings/Tiebreaker/BuchholzCutOne')

---Buchholz Cut 1 scoring each faced opponent by its points instead of its match diff
---@class TiebreakerBuchholzCutOnePoints : TiebreakerBuchholzCutOne
local TiebreakerBuchholzCutOnePoints = Class.new(TiebreakerBuchholzCutOne)

---@param member TiebreakerOpponent
---@return number
function TiebreakerBuchholzCutOnePoints:scoreOf(member)
	return member.points
end

---@return string
function TiebreakerBuchholzCutOnePoints:headerTitle()
	return 'Buchholz Cut 1 (Pts)'
end

return TiebreakerBuchholzCutOnePoints

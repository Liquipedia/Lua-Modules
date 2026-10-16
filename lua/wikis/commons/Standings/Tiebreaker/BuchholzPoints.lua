---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/BuchholzPoints
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerBuchholz = Lua.import('Module:Standings/Tiebreaker/Buchholz')

---Buchholz scoring each faced opponent by its points instead of its match diff
---@class TiebreakerBuchholzPoints : TiebreakerBuchholz
local TiebreakerBuchholzPoints = Class.new(TiebreakerBuchholz)

---@param member TiebreakerOpponent
---@return number
function TiebreakerBuchholzPoints:scoreOf(member)
	return member.points
end

---@return string
function TiebreakerBuchholzPoints:headerTitle()
	return 'Buchholz (Pts)'
end

return TiebreakerBuchholzPoints

---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/MedianBuchholzPoints
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerMedianBuchholz = Lua.import('Module:Standings/Tiebreaker/MedianBuchholz')

---Median-Buchholz scoring each faced opponent by its points instead of its match diff
---@class TiebreakerMedianBuchholzPoints : TiebreakerMedianBuchholz
local TiebreakerMedianBuchholzPoints = Class.new(TiebreakerMedianBuchholz)

---@param member TiebreakerOpponent
---@return number
function TiebreakerMedianBuchholzPoints:scoreOf(member)
	return member.points
end

---@return string
function TiebreakerMedianBuchholzPoints:headerTitle()
	return 'BH-M'
end

return TiebreakerMedianBuchholzPoints

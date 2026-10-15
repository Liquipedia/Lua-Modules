---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/MedianBuchholzPoints
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local TiebreakerBuchholzPoints = Lua.import('Module:Standings/Tiebreaker/BuchholzPoints')
local TiebreakerMedianBuchholz = Lua.import('Module:Standings/Tiebreaker/MedianBuchholz')

---Median-Buchholz scoring each faced opponent by its points instead of its match diff
---@class TiebreakerMedianBuchholzPoints : TiebreakerMedianBuchholz
local TiebreakerMedianBuchholzPoints = Class.new(TiebreakerMedianBuchholz)

TiebreakerMedianBuchholzPoints.scoreOf = TiebreakerBuchholzPoints.scoreOf

---@return string
function TiebreakerMedianBuchholzPoints:headerTitle()
	return 'Median-Buchholz (Pts)'
end

return TiebreakerMedianBuchholzPoints

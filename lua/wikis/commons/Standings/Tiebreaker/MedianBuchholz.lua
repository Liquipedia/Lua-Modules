---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/MedianBuchholz
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local TiebreakerBuchholz = Lua.import('Module:Standings/Tiebreaker/Buchholz')

---@class TiebreakerMedianBuchholz : TiebreakerBuchholz
local TiebreakerMedianBuchholz = Class.new(TiebreakerBuchholz)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return number
function TiebreakerMedianBuchholz:valueOf(state, opponent)
	local scores = self:opponentScores(state, opponent)
	-- With fewer than three scores there is nothing left once the highest and lowest are dropped
	if #scores < 3 then
		return 0
	end

	-- Only a single highest and a single lowest score are dropped, even when values are tied
	return MathUtil.sum(scores) - Array.max(scores) - Array.min(scores)
end

---@return string
function TiebreakerMedianBuchholz:headerTitle()
	return 'BH-M'
end

return TiebreakerMedianBuchholz

---
-- @Liquipedia
-- page=Module:Standings/Tiebreaker/BuchholzCutOne
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local TiebreakerBuchholz = Lua.import('Module:Standings/Tiebreaker/Buchholz')

---@class TiebreakerBuchholzCutOne : TiebreakerBuchholz
local TiebreakerBuchholzCutOne = Class.new(TiebreakerBuchholz)

---@param state TiebreakerOpponent[]
---@param opponent TiebreakerOpponent
---@return number
function TiebreakerBuchholzCutOne:valueOf(state, opponent)
	local scores = self:opponentScores(state, opponent)
	-- With fewer than two scores there is nothing left once the lowest is dropped
	if #scores < 2 then
		return 0
	end

	-- Only a single lowest score is dropped, even when values are tied
	return MathUtil.sum(scores) - Array.min(scores)
end

---@return string
function TiebreakerBuchholzCutOne:headerTitle()
	return 'Buchholz Cut 1'
end

return TiebreakerBuchholzCutOne

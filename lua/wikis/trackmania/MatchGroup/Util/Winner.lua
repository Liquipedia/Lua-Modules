---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Winner
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local OpponentDisplay = Lua.import('Module:OpponentDisplay')
local Ordinal = Lua.import('Module:Ordinal')

local Winner = {}

--- Determines whether a placement is within the top `winners` places.
---@param placement number|string|nil
---@param winners number|string|nil
---@return boolean
function Winner.isPlacementWinner(placement, winners)
	placement = tonumber(placement)
	winners = tonumber(winners) or 1
	return (placement ~= nil)
		and (placement > 0)
		and (placement <= winners)
end

--- Determines whether an opponent is highlighted as a winner based on placement.
---@param opponent standardOpponent
---@return boolean
function Winner.isWinner(opponent)
	if opponent.advances then
		return true
	end

	local extradata = opponent.extradata or {}
	return Winner.isPlacementWinner(opponent.placement, extradata.winners)
end

--- Returns the text to display in a bracket score cell:
--- score, then ordinal placement.
---@param opponent standardOpponent
---@return string?
function Winner.getScoreText(opponent)
	local scoreText = OpponentDisplay.InlineScore(opponent)
	if Logic.isEmpty(scoreText) and opponent.placement then
		return Ordinal.toOrdinal(opponent.placement, {superScript = true})
	end

	return scoreText
end

return Winner

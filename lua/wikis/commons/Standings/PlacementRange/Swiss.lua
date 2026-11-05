---
-- @Liquipedia
-- page=Module:Standings/PlacementRange/Swiss
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

---@class StandingsSwissFormat
---@field type 'swiss'
---@field winsToAdvance integer
---@field lossesToEliminate integer

---@alias StandingsRecordCounts table<integer, table<integer, integer>>
---@alias StandingsRecordRanges table<integer, table<integer, StandingsPlacementRangeValue>>

---Swiss and gsl: opponents meet opponents on the same record until they advance or are eliminated
---@class StandingsSwissPlacementRange: StandingsPlacementRangeCalculator
---@field format StandingsSwissFormat
---@field opponents StandingTableOpponentData[]
---@field finalRecordCounts StandingsRecordCounts
---@field rangesByRecord StandingsRecordRanges
local StandingsSwissPlacementRange = Class.new(function(self, format, opponents, finalRecordCounts, rangesByRecord)
	self.format = format
	self.opponents = opponents
	self.finalRecordCounts = finalRecordCounts
	self.rangesByRecord = rangesByRecord
end)

---Nil if the number of opponents does not fit the format.
---@param format StandingsSwissFormat
---@param opponents StandingTableOpponentData[]
---@return StandingsSwissPlacementRange?
function StandingsSwissPlacementRange.new(format, opponents)
	local finalRecordCounts = StandingsSwissPlacementRange.countFinalRecords(
		Array.map(opponents, function() return {w = 0, l = 0} end), format
	)
	if not finalRecordCounts then
		return nil
	end
	return StandingsSwissPlacementRange(
		format, opponents, finalRecordCounts, StandingsSwissPlacementRange.rangesFromFinalRecords(finalRecordCounts, format)
	)
end

---Number of opponents finishing on each record, `[wins][losses]`. Nil if the records do not fit the format.
---@param records {w: integer, l: integer}[]
---@param format StandingsSwissFormat
---@return StandingsRecordCounts?
function StandingsSwissPlacementRange.countFinalRecords(records, format)
	local active, final = {}, {}
	local function add(counts, wins, losses, count)
		counts[wins] = counts[wins] or {}
		counts[wins][losses] = (counts[wins][losses] or 0) + count
	end
	local function isFinal(wins, losses)
		return wins == format.winsToAdvance or losses == format.lossesToEliminate
	end

	local fitsFormat = Array.all(records, function(record)
		return record.w <= format.winsToAdvance and record.l <= format.lossesToEliminate
			and not (record.w == format.winsToAdvance and record.l == format.lossesToEliminate)
	end)
	if not fitsFormat then
		return nil
	end
	Array.forEach(records, function(record)
		add(isFinal(record.w, record.l) and final or active, record.w, record.l, 1)
	end)

	-- Records with fewer matches feed the later ones
	for level = 0, format.winsToAdvance + format.lossesToEliminate - 2 do
		for wins = 0, math.min(level, format.winsToAdvance - 1) do
			local losses = level - wins
			local count = (active[wins] or {})[losses] or 0
			if count % 2 == 1 then
				return nil
			end
			if count > 0 then
				add(isFinal(wins + 1, losses) and final or active, wins + 1, losses, count / 2)
				add(isFinal(wins, losses + 1) and final or active, wins, losses + 1, count / 2)
			end
		end
	end
	return final
end

---Best and worst final placement per record, `[wins][losses]`.
---@param finalRecordCounts StandingsRecordCounts
---@param format StandingsSwissFormat
---@return StandingsRecordRanges
function StandingsSwissPlacementRange.rangesFromFinalRecords(finalRecordCounts, format)
	-- Final records rank by wins, then fewer losses
	local ranges, first = {}, 1
	for wins = format.winsToAdvance, 0, -1 do
		ranges[wins] = {}
		for losses = 0, format.lossesToEliminate do
			local count = (finalRecordCounts[wins] or {})[losses]
			if count then
				ranges[wins][losses] = {first, first + count - 1}
				first = first + count
			end
		end
	end
	-- Other records reach the ranges after a win and after a loss
	for wins = format.winsToAdvance - 1, 0, -1 do
		for losses = format.lossesToEliminate - 1, 0, -1 do
			local afterWin, afterLoss = ranges[wins + 1][losses], ranges[wins][losses + 1]
			ranges[wins][losses] = {math.min(afterWin[1], afterLoss[1]), math.max(afterWin[2], afterLoss[2])}
		end
	end
	return ranges
end

---@param roundNumber integer
---@return boolean
function StandingsSwissPlacementRange:hasMatchAdjustment(roundNumber)
	return Array.any(self.opponents, function(opponentData)
		return Table.any(opponentData.adjustments or {}, function(adjustmentRound, adjustment)
			return adjustmentRound <= roundNumber and adjustment.match ~= nil
		end)
	end)
end

---@param entriesInRound StandingsPlacementRangeEntry[]
---@param roundNumber integer
---@return StandingsPlacementRangeValue[]?
function StandingsSwissPlacementRange:rangesFor(entriesInRound, roundNumber)
	local isEligible = Array.all(entriesInRound, function(entry)
		-- With overtime, the match record leaves out the overtime results
		return entry.match.d == 0
			and entry.overtime == nil
			and not entry.extradata.disqualified
	end)
	if not isEligible or self:hasMatchAdjustment(roundNumber) then
		return nil
	end
	-- Rejects records that same record pairings can not produce
	local finalRecordCounts = StandingsSwissPlacementRange.countFinalRecords(
		Array.map(entriesInRound, function(entry) return entry.match end), self.format
	)
	if not Logic.deepEquals(finalRecordCounts, self.finalRecordCounts) then
		return nil
	end
	return Array.map(entriesInRound, function(entry)
		return self.rangesByRecord[entry.match.w][entry.match.l]
	end)
end

return StandingsSwissPlacementRange

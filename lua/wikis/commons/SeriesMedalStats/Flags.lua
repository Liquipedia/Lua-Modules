---
-- @Liquipedia
-- page=Module:SeriesMedalStats/Flags
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local MedalStatsBase = Lua.import('Module:SeriesMedalStats')
local Opponent = Lua.import('Module:Opponent/Custom')

local MedalsTable = Lua.import('Module:Widget/MedalsTable')

---@class SeriesMedalStatsFlag: SeriesMedalStats
local MedalStats = Class.new(MedalStatsBase)

---@param frame Frame
---@return Widget?
function MedalStats.run(frame)
	local args = Arguments.getArgs(frame)

	--only query for solo opponents (only for them flag stats make sense)
	args.opponentTypes = Opponent.solo

	return MedalStats(args):create()
end

---@return Widget?
function MedalStats:create()
	if Logic.isEmpty(self.rawData) then return end

	---@param placement placement
	---@return string?
	local getIdentifier = function(placement)
		return (placement.opponentplayers or {}).p1flag
	end

	self.data = {}
	Array.forEach(self.rawData, FnUtil.curry(FnUtil.curry(self.processByIdentifier, self), getIdentifier))
	self.rawData = nil

	return MedalsTable{
		medalsTableType = 'Country',
		dataColumns = self.config.columns,
		data = self.data,
		renderRowFirstCell = function(identifier)
			return Flags.Icon{flag = identifier, shouldLink = false} .. ' ' .. Flags.CountryName{flag = identifier}
		end,
		rowSort = MedalStatsBase.rowSort,
		hideTotalRow = true,
		cutAfter = self.config.cutAfter,
	}
end

return MedalStats

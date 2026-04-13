---
-- @Liquipedia
-- page=Module:SeriesMedalStats/Faction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local MedalStatsBase = Lua.import('Module:SeriesMedalStats')
local Opponent = Lua.import('Module:Opponent/Custom')

local MedalsTable = Lua.import('Module:Widget/MedalsTable')

---@class SeriesMedalStatsFaction: SeriesMedalStats
local MedalStats = Class.new(MedalStatsBase)

---@param frame Frame
---@return Widget?
function MedalStats.run(frame)
	local args = Arguments.getArgs(frame)

	--only query for solo opponents (only for them faction stats make sense)
	args.opponentTypes = Opponent.solo

	return MedalStats(args):create()
end

---@return Widget?
function MedalStats:create()
	if Logic.isEmpty(self.rawData) then return end

	---@param placement placement
	---@return string?
	local getIdentifier = function(placement)
		return (placement.opponentplayers or {}).p1faction
	end

	self.data = {}
	Array.forEach(self.rawData, FnUtil.curry(FnUtil.curry(self.processByIdentifier, self), getIdentifier))
	self.rawData = nil

	return MedalsTable{
		medalsTableType = 'Faction',
		dataColumns = self.config.columns,
		data = self.data,
		renderRowFirstCell = function(identifier)
			return Faction.Icon{faction = identifier, showLink = false} .. ' ' .. Faction.toName(identifier)
		end,
		rowSort = MedalStatsBase.rowSort,
		hideTotalRow = true,
		cutAfter = self.config.cutAfter,
	}
end

return MedalStats

---
-- @Liquipedia
-- page=Module:SeriesMedalStats/Faction
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local MedalStatsBase = Lua.import('Module:SeriesMedalStats')

---@class SeriesMedalStatsFaction: SeriesMedalStats
local MedalStats = Class.new(MedalStatsBase)

function MedalStats.run(frame)
	local args = Arguments.getArgs(frame)

	--only query for solo opponents (only for them faction stats make sense)
	args.opponentTypes = Opponent.solo

	return MedalStats(args):query():create()
end

---@return Html?
function MedalStats:create()
	if Table.isEmpty(self.rawData) then return end

	self:_processData()

	local nameDisplay = function(identifier)
		return Faction.Icon{faction = identifier, showLink = false} .. ' ' .. Faction.toName(identifier)
	end

	return self:defaultBuild(nameDisplay, self.args.title or 'Race', self.args.cutAfterPartial or 'Races')
end

function MedalStats:_processData()
	---@param placement SeriesMedalStatsPlacementObject
	---@return string?
	local getIdentifier = function(placement)
		return (placement.opponentplayers or {}).p1faction
	end

	self.data = {}

	Array.forEach(self.rawData, function(placement)
		return self:processByIdentifier(getIdentifier, placement)
	end)

	self.rawData = nil

	self:sort()
end

return MedalStats

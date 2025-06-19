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
local Table = Lua.import('Module:Table')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local MedalStatsBase = Lua.import('Module:SeriesMedalStats')

---@class SeriesMedalStatsFlag: SeriesMedalStats
local MedalStats = Class.new(MedalStatsBase)

function MedalStats.run(frame)
	local args = Arguments.getArgs(frame)

	--only query for solo opponents (only for them flag stats make sense)
	args.opponentTypes = Opponent.solo

	return MedalStats(args):query():create()
end

---@return Html?
function MedalStats:create()
	if Table.isEmpty(self.rawData) then return end

	self:_processData()

	local nameDisplay = function(identifier)
		return Flags.Icon{flag = identifier, shouldLink = false} .. ' ' .. Flags.CountryName{flag = identifier}
	end

	return self:defaultBuild(nameDisplay, 'Country', 'Countries')
end

function MedalStats:_processData()
	---@param placement SeriesMedalStatsPlacementObject
	---@return string?
	local getIdentifier = function(placement)
		return (placement.opponentplayers or {}).p1flag
	end

	self.data = {}

	Array.forEach(self.rawData, function(placement)
		return self:processByIdentifier(getIdentifier, placement)
	end)

	self.rawData = nil

	self:sort()
end

return MedalStats

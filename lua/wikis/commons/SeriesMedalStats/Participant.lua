---
-- @Liquipedia
-- page=Module:SeriesMedalStats/Participant
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local MedalStatsBase = Lua.import('Module:SeriesMedalStats')

---@class SeriesMedalStatsParticipant: SeriesMedalStats
---@field teams table<string, string>
local MedalStats = Class.new(MedalStatsBase)

function MedalStats.run(frame)
	local args = Arguments.getArgs(frame)

	return MedalStats(args):query():create()
end

---@return Html?
function MedalStats:create()
	if Table.isEmpty(self.rawData) then return end

	self:_processData()

	local nameDisplay = function(identifier)
		return OpponentDisplay.BlockOpponent{opponent = self.opponents[identifier]}
	end

	return self:defaultBuild(nameDisplay, 'Participant', 'Participants')
end

function MedalStats:_processData()
	self.teams = {}
	self.opponents = {}

	---@param teamTemplate string
	---@return string?
	local resolveTeamToIdentifier = function(teamTemplate)
		local rawData = mw.ext.TeamTemplate.raw(teamTemplate)

		if not rawData or not rawData.page then return end

		local identifier = mw.ext.TeamLiquidIntegration.resolve_redirect(rawData.page):lower()

		self.teams[teamTemplate] = identifier

		return identifier
	end

	---@param placement SeriesMedalStatsPlacementObject
	---@return string?
	local getIdentifier = function(placement)
		if placement.opponenttype == Opponent.literal or not placement.opponentname then return end

		if placement.opponenttype ~= Opponent.team then
			local identifier = placement.opponentname
			self.opponents[identifier] = Opponent.fromLpdbStruct(placement)

			if Opponent.isTbd(self.opponents[identifier]) then return end

			return identifier
		end

		local teamTemplate = placement.opponentname
		if String.isEmpty(teamTemplate) then
			return
		end
		---@cast teamTemplate -nil

		teamTemplate = teamTemplate:lower():gsub('_', ' ')

		local identifier = self.teams[teamTemplate] or resolveTeamToIdentifier(teamTemplate)
		self.opponents[identifier] = Opponent.fromLpdbStruct(placement)

		if Opponent.isTbd(self.opponents[identifier]) then return end

		return identifier
	end

	self.data = {}

	Array.forEach(self.rawData, function(placement)
		return self:processByIdentifier(getIdentifier, placement)
	end)

	self.rawData = nil

	self:sort()
end

return MedalStats

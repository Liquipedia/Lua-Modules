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
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local MedalStatsBase = Lua.import('Module:SeriesMedalStats')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local MedalsTable = Lua.import('Module:Widget/MedalsTable')

local String = Lua.import('Module:StringUtils')


---@class SeriesMedalStatsParticipant: SeriesMedalStats
---@field teams table<string, string>
---@field opponents table<string, standardOpponent>
local MedalStats = Class.new(MedalStatsBase)

---@param frame Frame
---@return Widget?
function MedalStats.run(frame)
	local args = Arguments.getArgs(frame)

	return MedalStats(args):create()
end

---@return Html?
function MedalStats:create()
	if Logic.isEmpty(self.rawData) then return end

	self:_processData()

	return MedalsTable{
		medalsTableType = 'Participant',
		dataColumns = self.config.columns,
		data = self.data,
		renderRowFirstCell = function(identifier)
			return OpponentDisplay.BlockOpponent{opponent = self.opponents[identifier]}
		end,
		rowSort = MedalStatsBase.rowSort,
		hideTotalRow = true,
		cutAfter = self.config.cutAfter,
	}
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

	---@param placement placement
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
	Array.forEach(self.rawData, FnUtil.curry(FnUtil.curry(self.processByIdentifier, self), getIdentifier))
	self.rawData = nil
end

return MedalStats

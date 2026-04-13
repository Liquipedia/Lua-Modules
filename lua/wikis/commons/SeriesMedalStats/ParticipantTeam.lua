---
-- @Liquipedia
-- page=Module:SeriesMedalStats/ParticipantTeam
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

---@class SeriesMedalStatsParticipantTeam: SeriesMedalStats
---@field teams table<string, string>
local MedalStats = Class.new(MedalStatsBase)

---@param frame Frame
---@return Widget?
function MedalStats.run(frame)
	local args = Arguments.getArgs(frame)

	--only query for solo opponents (only for them participantTeam stats make sense)
	args.opponentTypes = Opponent.solo

	--reduce due to having text above
	args.cutafter = tonumber(args.cutafter) or 5

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
			return OpponentDisplay.BlockOpponent{opponent = {
				type = Opponent.team,
				template = identifier,
				extradata = {},
			}}
		end,
		rowSort = MedalStatsBase.rowSort,
		hideTotalRow = true,
		cutAfter = self.config.cutAfter,
		footer = '',--todo
	}
--[[
	return mw.html.create()
		:tag('b'):wikitext('Note'):done()
		:wikitext(': Medals won per Team shows the team that a player was<br>on when the medal was won, ')
		:tag('b'):wikitext('not'):done()
		:wikitext(' their current team.')
		:node(display)
]]
end

function MedalStats:_processData()
	self.teams = {}

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
		local teamTemplate = (placement.opponentplayers or {}).p1team
		if Logic.isEmpty(teamTemplate) then
			return
		end
		---@cast teamTemplate -nil

		teamTemplate = teamTemplate:lower():gsub('_', ' ')

		return self.teams[teamTemplate] or resolveTeamToIdentifier(teamTemplate)
	end

	self.data = {}
	Array.forEach(self.rawData, FnUtil.curry(FnUtil.curry(self.processByIdentifier, self), getIdentifier))
	self.rawData = nil
end

return MedalStats

---
-- @Liquipedia
-- page=Module:SeriesMedalStats/ParticipantTeam
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local MedalStatsBase = Lua.import('Module:SeriesMedalStats')

---@class SeriesMedalStatsParticipantTeam: SeriesMedalStats
---@field teams table<string, string>
local MedalStats = Class.new(MedalStatsBase)

function MedalStats.run(frame)
	local args = Arguments.getArgs(frame)

	--only query for solo opponents (only for them participantTeam stats make sense)
	args.opponentTypes = Opponent.solo

	--reduce due to having text above
	args.cutafter = tonumber(args.cutafter) or 5

	return MedalStats(args):query():create()
end

---@return Html?
function MedalStats:create()
	if Table.isEmpty(self.rawData) then return end

	self:_processData()

	local nameDisplay = function(identifier)
		return mw.ext.TeamTemplate.team(identifier)
	end

	local display = self:defaultBuild(nameDisplay, 'Team', 'Teams')
	if not display then return end

	return mw.html.create()
		:tag('b'):wikitext('Note'):done()
		:wikitext(': Medals won per Team shows the team that a player was<br>on when the medal was won, ')
		:tag('b'):wikitext('not'):done()
		:wikitext(' their current team.')
		:node(display)
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

	---@param placement SeriesMedalStatsPlacementObject
	---@return string?
	local getIdentifier = function(placement)
		local teamTemplate = (placement.opponentplayers or {}).p1team
		if String.isEmpty(teamTemplate) then
			return
		end
		---@cast teamTemplate -nil

		teamTemplate = teamTemplate:lower():gsub('_', ' ')

		return self.teams[teamTemplate] or resolveTeamToIdentifier(teamTemplate)
	end

	self.data = {}

	Array.forEach(self.rawData, function(placement)
		return self:processByIdentifier(getIdentifier, placement)
	end)

	self.rawData = nil

	self:sort()
end

return MedalStats

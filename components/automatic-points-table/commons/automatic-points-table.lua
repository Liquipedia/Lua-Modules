---
-- @Liquipedia
-- wiki=commons
-- page=Module:AutomaticPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Condition = require('Module:Condition')
local Json = require('Module:Json')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local AutomaticPointsTable = Class.new(
	function(self, frame)
		self.frame = frame
		self.args = Arguments.getArgs(frame)
		self.parsedInput = self:parseInput(self.args)
	end
)

function AutomaticPointsTable.run(frame)
	local pointsTable = AutomaticPointsTable(frame)

	local tournaments = pointsTable.parsedInput.tournaments
	local tournamentsWithPlacements = pointsTable:queryPlacements(tournaments)

	mw.logObject(pointsTable.parsedInput.pbg)
	mw.logObject(pointsTable.parsedInput.tournaments)
	mw.logObject(pointsTable.parsedInput.teams)
	mw.logObject(tournamentsWithPlacements)

	return nil
end

function AutomaticPointsTable:parseInput(args)
	local pbg = self:parsePositionBackgroundData(args)
	local tournaments = self:parseTournaments(args)
	local teams = self:parseTeams(args, #tournaments)
	return {
		pbg = pbg,
		tournaments = tournaments,
		teams = teams
	}
end

--- parses the pbg arguments, these are the background colors of specific positions
--- Usually used to indicate where a team in a specific position will end up qualifying to
function AutomaticPointsTable:parsePositionBackgroundData(args)
	local pbg = {}
	for _, background in Table.iter.pairsByPrefix(args, 'pbg') do
		table.insert(pbg, background)
	end
	return pbg
end

function AutomaticPointsTable:parseTournaments(args)
	local tournaments = {}
	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament') do
		table.insert(tournaments, (Json.parse(tournament)))
	end
	return tournaments
end

function AutomaticPointsTable:parseTeams(args, tournamentCount)
	local teams = {}
	for _, team in Table.iter.pairsByPrefix(args, 'team') do
		local parsedTeam = Json.parse(team)
		parsedTeam.aliases = self:parseAliases(parsedTeam, tournamentCount)
		parsedTeam.deductions = self:parseDeductions(parsedTeam, tournamentCount)
		parsedTeam.manualPoints = self:parseManualPoints(parsedTeam, tournamentCount)
		table.insert(teams, parsedTeam)
	end
	return teams
end

--- Parses the team aliases, used in cases where a team is picked up by an org or changed name in some
--- of the tournaments, in which case aliases are required to correctly query the team's results & points
function AutomaticPointsTable:parseAliases(team, tournamentCount)
	local aliases = {}
	for index = 1, tournamentCount do
		if String.isNotEmpty(team['alias' .. index]) then
			aliases[index] = team['alias' .. index]
		end
	end
	return aliases
end

--- Parses the teams' deductions, used in cases where a team has disbanded or made a roster change
--- that causes them to lose a portion or all of their points that they've accumulated up until that change
function AutomaticPointsTable:parseDeductions(team, tournamentCount)
	local deductions = {}
	for index = 1, tournamentCount do
		if String.isNotEmpty(team['deduction' .. index]) then
			if not deductions[index] then
				deductions[index] = {}
			end
			deductions[index].amount = tonumber(team['deduction' .. index])

			if String.isNotEmpty(team['deduction' .. index .. 'note']) then
				deductions[index].note = team['deduction' .. index .. 'note']
			end
		end
	end

	return deductions
end

function AutomaticPointsTable:parseManualPoints(team, tournamentCount)
	local manualPoints = {}
	for index = 1, tournamentCount do
		if String.isNotEmpty(team['points' .. index]) then
			manualPoints[index] = tonumber(team['points' .. index])
		end
	end
	return manualPoints
end

function AutomaticPointsTable:queryPlacements(tournaments)
	local queryParams = {
		limit = 5000,
		query = 'tournament, participant, placement, extradata'
	}

	local tree = ConditionTree(BooleanOperator.any)
	local columnName = ColumnName('tournament')
	local tournamentIndices = {}
	Table.iter.forEachIndexed(tournaments,
		function(index, t)
			tree:add(ConditionNode(columnName, Comparator.eq, t.name))
			tournamentIndices[t.name] = index
			t.placements = {}
		end
	)
	local conditions = tree:toString()

	queryParams.conditions = conditions
	local allQueryResult = mw.ext.LiquipediaDB.lpdb('placement', queryParams)

	Table.iter.forEach(allQueryResult,
		function(result)
			local tournamentIndex = tournamentIndices[result.tournament]
			local tournament = tournaments[tournamentIndex]

			result.points = tonumber(result.extradata.prizepoints)
			result.securedPoints = tonumber(result.extradata.securedpoints)
			table.insert(tournament.placements, result)
		end
	)

	return tournaments
end

return AutomaticPointsTable

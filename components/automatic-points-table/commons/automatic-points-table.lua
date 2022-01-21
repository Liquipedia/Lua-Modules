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

local _POINTS_TYPE = {
	MANUAL = 'MANUAL',
	PRIZE = 'PRIZE',
	SECURED = 'SECURED'
}

local AutomaticPointsTable = Class.new(
	function(self, frame)
		self.frame = frame
		self.args = Arguments.getArgs(frame)
		self.parsedInput = self:parseInput(self.args)
	end
)

function AutomaticPointsTable.run(frame)
	local pointsTable = AutomaticPointsTable(frame)

	local teams = pointsTable.parsedInput.teams
	local tournaments = pointsTable.parsedInput.tournaments
	local teamsWithResults, tournamentsWithResults = pointsTable:queryPlacements(teams, tournaments)
	local pointsData = pointsTable:getPointsData(teamsWithResults, tournamentsWithResults)
	local sortedData = pointsTable:sortData(pointsData)
	local sortedDataWithPositions = pointsTable:addPositionData(sortedData)

	-- mw.logObject(pointsTable.parsedInput.pbg)
	-- mw.logObject(pointsTable.parsedInput.tournaments)
	-- mw.logObject(pointsTable.parsedInput.teams)
	-- mw.logObject(tournamentsWithPlacements)
	mw.logObject(sortedDataWithPositions)

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
		parsedTeam.results = {}
		table.insert(teams, parsedTeam)
	end
	return teams
end

--- Parses the team aliases, used in cases where a team is picked up by an org or changed
--- name in some of the tournaments, in which case aliases are required to correctly query
--- the team's results & points
function AutomaticPointsTable:parseAliases(team, tournamentCount)
	local aliases = {}
	local lastAlias = team.name
	for index = 1, tournamentCount do
		if String.isNotEmpty(team['alias' .. index]) then
			lastAlias = team['alias' .. index]
		end
		aliases[index] = lastAlias
	end
	return aliases
end

--- Parses the teams' deductions, used in cases where a team has disbanded or made a roster
--- change that causes them to lose a portion or all of their points that they've accumulated
--- up until that change
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

function AutomaticPointsTable:generateReverseAliases(teams, tournaments)
	local reverseAliases = {}
	for tournamentIndex = 1, #tournaments do
		reverseAliases[tournamentIndex] = {}
		Table.iter.forEachIndexed(teams,
			function(index, team)
				local alias = mw.language.getContentLanguage():ucfirst(team.aliases[tournamentIndex])
				reverseAliases[tournamentIndex][alias] = index
			end
		)
	end
	return reverseAliases
end


function AutomaticPointsTable:queryPlacements(teams, tournaments)
	-- to get a team index, use reverseAliases[tournamentIndex][alias]
	local reverseAliases = self:generateReverseAliases(teams, tournaments)

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

			result.prizePoints = tonumber(result.extradata.prizepoints)
			result.securedPoints = tonumber(result.extradata.securedpoints)
			result.extradata = nil
			table.insert(tournament.placements, result)

			local participant = result.participant
			local teamIndex = reverseAliases[tournamentIndex][participant]
			if teamIndex ~= nil then
				teams[teamIndex].results[tournamentIndex] = result
			end
		end
	)

	return teams, tournaments
end

function AutomaticPointsTable:getPointsData(teams, tournaments)
	return Table.mapValues(teams,
		function(team)
			local teamPointsData = {}
			local totalPoints = 0
			for tournamentIndex = 1, #tournaments do
				local manualPoints = team.manualPoints[tournamentIndex]
				local placement = team.results[tournamentIndex]

				local pointsForTournament = self:calculatePointsForTournament(placement, manualPoints)
				if Table.isNotEmpty(pointsForTournament) then
					totalPoints = totalPoints + pointsForTournament.amount
				end

				local deduction = team.deductions[tournamentIndex]
				if Table.isNotEmpty(deduction) then
					pointsForTournament.deduction = deduction
					-- will only show the deductions column if there's atleast one team with
					-- some deduction for a tournament
					tournaments[tournamentIndex].shouldDeductionsBeVisible = true
					totalPoints = totalPoints - (deduction.amount or 0)
				end

				teamPointsData[tournamentIndex] = pointsForTournament
			end

			teamPointsData.team = team
			teamPointsData.totalPoints = totalPoints
			return teamPointsData
		end
	)
end

function AutomaticPointsTable:calculatePointsForTournament(placement, manualPoints)
	-- manual points get highest priority
	if manualPoints ~= nil then
		return {
			amount = manualPoints,
			type = _POINTS_TYPE.MANUAL
		}
	-- placement points get next priority
	elseif placement ~= nil then
		local prizePoints = placement.prizePoints
		local securedPoints = placement.securedPoints
		if prizePoints ~= nil then
			return {
				amount = prizePoints,
				type = _POINTS_TYPE.PRIZE
			}
		-- secured points are the points that are guaranteed for a team in a tournament
		-- a team with X secured points will get X or more points at the end of the tournament
		elseif securedPoints ~= nil then
			return {
				amount = securedPoints,
				type = _POINTS_TYPE.SECURED
			}
		end
	end

	return {}
end

--- sort by total points (desc) then by name (asc)
function AutomaticPointsTable:sortData(pointsData, teams)
	table.sort(pointsData,
		function(a, b)
			if a.totalPoints == b.totalPoints then
				local aName = a.team.aliases[#a.team.aliases]
				local bName = b.team.aliases[#b.team.aliases]
				return aName < bName
			else
				return a.totalPoints > b.totalPoints
			end
		end
	)

	return pointsData
end

function AutomaticPointsTable:addPositionData(pointsData)
	local maxPoints = pointsData[1].totalPoints

	local teamPosition = 0
	local previousTeamPoints = maxPoints + 1

	return Table.map(pointsData,
		function(index, dataPoint)
			if dataPoint.totalPoints < previousTeamPoints then
				teamPosition = index
			end
			dataPoint.position = teamPosition
			previousTeamPoints = dataPoint.totalPoints
			return index, dataPoint

		end
	)
end

return AutomaticPointsTable

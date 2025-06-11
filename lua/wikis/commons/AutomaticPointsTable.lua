---
-- @Liquipedia
-- page=Module:AutomaticPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Condition = require('Module:Condition')
local TableDisplay = require('Module:AutomaticPointsTable/Display')
local MinifiedDisplay = require('Module:AutomaticPointsTable/MinifiedDisplay')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local POINTS_TYPE = {
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
	local positionBackgrounds = pointsTable.parsedInput.positionBackgrounds
	local limit = pointsTable.parsedInput.limit

	-- A display module is a module that takes in 3 arguments and returns some html,
	-- which will be displayed when this module is invoked
	local usedDisplayModule
	if pointsTable.parsedInput.shouldTableBeMinified then
		usedDisplayModule = MinifiedDisplay
	else
		usedDisplayModule = TableDisplay
	end

	pointsTable:storeLPDB(sortedDataWithPositions)

	local divTable = usedDisplayModule(
		sortedDataWithPositions,
		tournamentsWithResults,
		positionBackgrounds,
		limit
	)

	return divTable:create()
end

function AutomaticPointsTable:storeLPDB(pointsData)
	local date = os.date()
	Array.forEach(pointsData, function(teamPointsData)
		local team = teamPointsData.team
		local teamName = string.lower(team.aliases[#team.aliases])
		local lpdbName = self.parsedInput.lpdbName
		local uniqueId = teamName .. '_' .. lpdbName
		local position = teamPointsData.position
		local totalPoints = teamPointsData.totalPoints
		local objectData = {
			type = 'automatic_points',
			name = teamName,
			information = position,
			date = date,
			extradata = mw.ext.LiquipediaDB.lpdb_create_json({
				position = position,
				totalPoints = totalPoints
			})
		}

		mw.ext.LiquipediaDB.lpdb_datapoint(uniqueId, objectData)
	end)
end

function AutomaticPointsTable:parseInput(args)
	local positionBackgrounds = self:parsePositionBackgroundData(args)
	local tournaments = self:parseTournaments(args)
	local shouldResolveRedirect = Logic.readBool(args.resolveRedirect)
	local teams = self:parseTeams(args, #tournaments, shouldResolveRedirect)
	local minified = Logic.readBool(args.minified)
	local limit = tonumber(args.limit) or #teams
	local lpdbName = args.lpdbName or mw.title.getCurrentTitle().text

	return {
		positionBackgrounds = positionBackgrounds,
		tournaments = tournaments,
		teams = teams,
		shouldTableBeMinified = minified,
		limit = limit,
		lpdbName = lpdbName,
		shouldResolveRedirect = shouldResolveRedirect,
	}
end

--- parses the positionbg arguments, these are the background colors of specific
--- positions, usually used to indicate if a team in a specific position will end up qualifying
function AutomaticPointsTable:parsePositionBackgroundData(args)
	local positionBackgrounds = {}
	for _, background in Table.iter.pairsByPrefix(args, 'positionbg') do
		table.insert(positionBackgrounds, background)
	end
	return positionBackgrounds
end

function AutomaticPointsTable:parseTournaments(args)
	local tournaments = {}
	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament') do
		table.insert(tournaments, (Json.parse(tournament)))
	end
	return tournaments
end

function AutomaticPointsTable:parseTeams(args, tournamentCount, shouldResolveRedirect)
	local teams = {}
	for _, team in Table.iter.pairsByPrefix(args, 'team') do
		local parsedTeam = Json.parse(team)
		parsedTeam.aliases = self:parseAliases(parsedTeam, tournamentCount, shouldResolveRedirect)
		parsedTeam.deductions = self:parseDeductions(parsedTeam, tournamentCount)
		parsedTeam.manualPoints = self:parseManualPoints(parsedTeam, tournamentCount)
		parsedTeam.tiebreakerPoints = tonumber(parsedTeam.tiebreaker_points) or 0
		parsedTeam.results = {}
		table.insert(teams, parsedTeam)
	end
	return teams
end

--- Parses the team aliases, used in cases where a team is picked up by an org or changed
--- name in some of the tournaments, in which case aliases are required to correctly query
--- the team's results & points
function AutomaticPointsTable:parseAliases(team, tournamentCount, shouldResolveRedirect)
	local aliases = {}
	local parseAlias = function(x)
		if (shouldResolveRedirect) then
			return mw.ext.TeamLiquidIntegration.resolve_redirect(x)
		end
		return mw.language.getContentLanguage():ucfirst(x)
	end
	local lastAlias = team.name
	for index = 1, tournamentCount do
		if String.isNotEmpty(team['alias' .. index]) then
			lastAlias = team['alias' .. index]
		end
		aliases[index] = parseAlias(lastAlias)
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
	local shouldResolveRedirect = self.parsedInput.shouldResolveRedirect
	for tournamentIndex = 1, #tournaments do
		reverseAliases[tournamentIndex] = {}
		Array.forEach(teams,
			function(team, index)
				local alias
				if shouldResolveRedirect then
					alias = mw.ext.TeamLiquidIntegration.resolve_redirect(team.aliases[tournamentIndex])
				else
					alias = team.aliases[tournamentIndex]
				end
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
	Array.forEach(tournaments,
		function(t, index)
			tree:add(ConditionNode(columnName, Comparator.eq, t.name))
			tournamentIndices[t.name] = index
			t.placements = {}
		end
	)
	local conditions = tree:toString()

	queryParams.conditions = conditions
	local allQueryResult = mw.ext.LiquipediaDB.lpdb('placement', queryParams)

	Array.forEach(allQueryResult,
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
			teamPointsData.tiebreakerPoints = team.tiebreakerPoints
			return teamPointsData
		end
	)
end

function AutomaticPointsTable:calculatePointsForTournament(placement, manualPoints)
	-- manual points get highest priority
	if manualPoints ~= nil then
		return {
			amount = manualPoints,
			type = POINTS_TYPE.MANUAL
		}
	-- placement points get next priority
	elseif placement ~= nil then
		local prizePoints = placement.prizePoints
		local securedPoints = placement.securedPoints
		if prizePoints ~= nil then
			return {
				amount = prizePoints,
				type = POINTS_TYPE.PRIZE
			}
		-- secured points are the points that are guaranteed for a team in a tournament
		-- a team with X secured points will get X or more points at the end of the tournament
		elseif securedPoints ~= nil then
			return {
				amount = securedPoints,
				type = POINTS_TYPE.SECURED
			}
		end
	end

	return {}
end

--- sort by total points (desc) then by name (asc)
function AutomaticPointsTable:sortData(pointsData, teams)
	table.sort(pointsData,
		function(a, b)
			if a.totalPoints ~= b.totalPoints then
				return a.totalPoints > b.totalPoints
			end
			if a.tiebreakerPoints ~= b.tiebreakerPoints then
				return a.tiebreakerPoints > b.tiebreakerPoints
			end
			local aName = a.team.aliases[#a.team.aliases]
			local bName = b.team.aliases[#b.team.aliases]
			return aName < bName
		end
	)

	return pointsData
end

function AutomaticPointsTable:addPositionData(pointsData)
	local teamPosition = 0
	local previousTotalPoints = pointsData[1].totalPoints + 1
	local previousTiebreakerPoints = pointsData[1].tiebreakerPoints + 1

	return Table.map(pointsData,
		function(index, dataPoint)
			local lessTotalPoints = dataPoint.totalPoints < previousTotalPoints
			local equalTotalPoints = dataPoint.totalPoints == previousTotalPoints
			local lessTiebreakerPoints = dataPoint.tiebreakerPoints < previousTiebreakerPoints
			if lessTotalPoints or (equalTotalPoints and lessTiebreakerPoints) then
				teamPosition = index
			end
			dataPoint.position = teamPosition
			previousTotalPoints = dataPoint.totalPoints
			previousTiebreakerPoints = dataPoint.tiebreakerPoints

			return index, dataPoint
		end
	)
end

return AutomaticPointsTable

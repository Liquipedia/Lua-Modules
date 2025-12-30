---
-- @Liquipedia
-- page=Module:AutomaticPointsTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Condition = Lua.import('Module:Condition')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tournament = Lua.import('Module:Tournament')

local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local AutomaticPointsTableWidget = Lua.import('Module:Widget/AutomaticPointsTable')

---@enum PointsType
local POINTS_TYPE = {
	MANUAL = 'MANUAL',
	PRIZE = 'PRIZE',
	SECURED = 'SECURED'
}

---@class AutomaticPointsTableConfig
---@field positionBackgrounds string[]
---@field tournaments StandardTournament[]
---@field opponents AutomaticPointsTableOpponent[]
---@field shouldTableBeMinified boolean
---@field limit number
---@field lpdbName string
---@field shouldResolveRedirect boolean

---@class AutomaticPointsTableOpponent
---@field opponent standardOpponent
---@field aliases string[][]
---@field tiebreakerPoints number
---@field results {type: PointsType?, amount: number?, deduction: number?, note: string?}[]
---@field totalPoints number
---@field placement integer
---@field background string?
---@field note string?

---@class AutomaticPointsTable
---@operator call(Frame): AutomaticPointsTable
---@field args table
---@field parsedInput AutomaticPointsTableConfig
local AutomaticPointsTable = Class.new(
	function(self, frame)
		self.frame = frame
		self.args = Arguments.getArgs(frame)
		self.parsedInput = self:parseInput(self.args)
	end
)

---@param frame Frame
---@return Widget
function AutomaticPointsTable.run(frame)
	local pointsTable = AutomaticPointsTable(frame):process()
	mw.logObject(pointsTable.opponents, 'opponents')
	return pointsTable:display()
end

---@param opponents AutomaticPointsTableOpponent[]
function AutomaticPointsTable:storeLPDB(opponents)
	local date = DateExt.getContextualDateOrNow()
	Array.forEach(opponents, function(opponent)
		local teamName = Opponent.toName(opponent.opponent)
		local lpdbName = self.parsedInput.lpdbName
		local uniqueId = teamName .. '_' .. lpdbName
		local position = opponent.placement
		local totalPoints = opponent.totalPoints
		local objectData = {
			type = 'automatic_points',
			name = teamName,
			information = position,
			date = date,
			extradata = {
				position = position,
				totalPoints = totalPoints
			}
		}

		mw.ext.LiquipediaDB.lpdb_datapoint(uniqueId, Json.stringifySubTables(objectData))
	end)
end

---@param args table
---@return AutomaticPointsTableConfig
function AutomaticPointsTable:parseInput(args)
	local positionBackgrounds = self:parsePositionBackgroundData(args)
	local tournaments = self:parseTournaments(args)
	local opponents = self:parseOpponents(args, tournaments)
	local minified = Logic.readBool(args.minified)
	local limit = tonumber(args.limit) or #opponents
	local lpdbName = args.lpdbName or mw.title.getCurrentTitle().text

	return {
		positionBackgrounds = positionBackgrounds,
		tournaments = tournaments,
		opponents = opponents,
		shouldTableBeMinified = minified,
		limit = limit,
		lpdbName = lpdbName
	}
end

--- parses the positionbg arguments, these are the background colors of specific
--- positions, usually used to indicate if a team in a specific position will end up qualifying
---@param args table
---@return string[]
function AutomaticPointsTable:parsePositionBackgroundData(args)
	local positionBackgrounds = {}
	for _, background in Table.iter.pairsByPrefix(args, 'positionbg') do
		table.insert(positionBackgrounds, background)
	end
	return positionBackgrounds
end

---@param args table
---@return StandardTournament[]
function AutomaticPointsTable:parseTournaments(args)
	local tournaments = {}
	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament') do
		Array.appendWith(tournaments, Tournament.getTournament(tournament))
	end
	return tournaments
end

---@param args table
---@param tournaments StandardTournament[]
---@return AutomaticPointsTableOpponent[]
function AutomaticPointsTable:parseOpponents(args, tournaments)
	local opponents = {}
	for _, opponentArgs in Table.iter.pairsByPrefix(args, 'opponent') do
		local parsedArgs = Json.parseIfString(opponentArgs)
		local parsedOpponent = {
			opponent = Opponent.readOpponentArgs(parsedArgs),
			tiebreakerPoints = tonumber(parsedArgs.tiebreaker) or 0,
			background = parsedArgs.bg,
			note = parsedArgs.note,
		}
		assert(parsedOpponent.opponent.type == Opponent.team)
		assert(not Opponent.isTbd(parsedOpponent.opponent))
		local aliases = self:parseAliases(parsedArgs, parsedOpponent.opponent, #tournaments)

		parsedOpponent.results = Array.map(tournaments, function (tournament, tournamentIndex)
			local manualPoints = parsedArgs['points' .. tournamentIndex]
			if String.isNotEmpty(manualPoints) then
				return Table.mergeInto({
					type = POINTS_TYPE.MANUAL,
					amount = tonumber(manualPoints)
				}, self:parseDeduction(parsedArgs, tournamentIndex))
			end

			local queriedPoints = self:queryPlacement(aliases[tournamentIndex], tournament)

			if not queriedPoints then
				return {}
			end

			return Table.merge(queriedPoints, self:parseDeduction(parsedArgs, tournamentIndex))
		end)

		parsedOpponent.totalPoints = Array.reduce(parsedOpponent.results, function (aggregate, result)
			return aggregate + (result.amount or 0) - (result.deduction or 0)
		end, 0)

		Array.appendWith(opponents, parsedOpponent)
	end
	return opponents
end

--- Parses the team aliases, used in cases where a team is picked up by an org or changed
--- name in some of the tournaments, in which case aliases are required to correctly query
--- the team's results & points
---@param args table
---@param opponent standardOpponent
---@param tournamentCount integer
---@return string[][]
function AutomaticPointsTable:parseAliases(args, opponent, tournamentCount)
	local aliases = {}
	local lastAliases = TeamTemplate.queryHistoricalNames(Opponent.toName(opponent))

	for index = 1, tournamentCount do
		if String.isNotEmpty(args['alias' .. index]) then
			lastAliases = TeamTemplate.queryHistoricalNames(args['alias' .. index])
		end
		aliases[index] = lastAliases
	end
	return aliases
end

--- Parses the teams' deductions, used in cases where a team has disbanded or made a roster
--- change that causes them to lose a portion or all of their points that they've accumulated
--- up until that change
---@param args table
---@param index integer
---@return {deduction: number?, note: string?}[]
function AutomaticPointsTable:parseDeduction(args, index)
	local deduction = args['deduction' .. index]
	if String.isEmpty(deduction) then
		return {}
	elseif not Logic.isNumeric(deduction) then
		return {}
	end
	return {
		deduction = tonumber(deduction),
		note = args['deduction' .. index .. 'note']
	}
end

---@param aliases string[]
---@param tournament StandardTournament
function AutomaticPointsTable:queryPlacement(aliases, tournament)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('parent'), Comparator.eq, tournament.pageName),
		ConditionNode(ColumnName('opponenttype'), Comparator.eq, Opponent.team),
		Condition.Util.anyOf(ColumnName('opponenttemplate'), aliases),
	}
	local result = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = tostring(conditions),
		limit = 1,
		query = 'extradata'
	})[1]

	if not result then
		return
	end

	local prizePoints = tonumber(result.extradata.prizepoints)
	local securedPoints = tonumber(result.extradata.securedpoints)

	if prizePoints then
		return {
			amount = prizePoints,
			type = POINTS_TYPE.PRIZE,
		}
	elseif securedPoints then
		return {
			amount = securedPoints,
			type = POINTS_TYPE.SECURED,
		}
	end
end

---@param placement {prizePoints: number?, securedPoints: number?}
---@param manualPoints number?
---@return {amount: number?, type: PointsType?}
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
---@param opponents AutomaticPointsTableOpponent[]
---@return AutomaticPointsTableOpponent[]
function AutomaticPointsTable:sortData(opponents)
	return Array.sortBy(opponents, FnUtil.identity,
		---@param opp1 AutomaticPointsTableOpponent
		---@param opp2 AutomaticPointsTableOpponent
		function (opp1, opp2)
			local totalPoints1 = opp1.totalPoints
			local totalPoints2 = opp2.totalPoints
			if totalPoints1 ~= totalPoints2 then
				return totalPoints1 > totalPoints2
			elseif opp1.tiebreakerPoints ~= opp2.tiebreakerPoints then
				return opp1.tiebreakerPoints > opp2.tiebreakerPoints
			end
			return Opponent.toName(opp1.opponent) < Opponent.toName(opp2.opponent)
		end
	)
end

---@param opponents AutomaticPointsTableOpponent[]
---@return AutomaticPointsTableOpponent[]
function AutomaticPointsTable:addPlacements(opponents)
	Array.forEach(opponents, function (opponent, index)
		if index == 1 then
			opponent.placement = index
		elseif opponent.totalPoints ~= opponents[index - 1].totalPoints then
			opponent.placement = index
		elseif opponent.tiebreakerPoints ~= opponents[index - 1].totalPoints then
			opponent.placement = index
		else
			opponent.placement = opponents[index - 1].placement
		end
	end)
	return opponents
end

---@return self
function AutomaticPointsTable:process()
	self.opponents = self:addPlacements(self:sortData(self.parsedInput.opponents))
	if Lpdb.isStorageEnabled() then
		self:storeLPDB(self.opponents)
	end
	return self
end

---@return Widget
function AutomaticPointsTable:display()
	return AutomaticPointsTableWidget{
		opponents = self.opponents,
		tournaments = self.parsedInput.tournaments,
		limit = self.parsedInput.limit,
		positionBackgrounds = self.parsedInput.positionBackgrounds,
	}
end

return AutomaticPointsTable

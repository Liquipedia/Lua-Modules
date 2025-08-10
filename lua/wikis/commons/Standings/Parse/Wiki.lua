---
-- @Liquipedia
-- page=Module:Standings/Parse/Wiki
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Operator = Lua.import('Module:Operator')
local Opponent = Lua.import('Module:Opponent/Custom')
local Table = Lua.import('Module:Table')

local TiebreakerFactory = Lua.import('Module:Standings/Tiebreaker/Factory')

local StandingsParseWiki = {}

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

--[[
{{FfaStandings|title=League Standings
|bg=1-10=stay, 11-20=down
|matches=...,...,...
<!-- Rounds -->
|round1={{Round|title=A vs B|started=true|finished=false}}
<more rounds>
<!-- Opponents -->
|{{TeamOpponent|dreamfire|r1=17|r2=-|r3=-|r4=34|r5=32|r6=-}}
<more opponents>
}}
]]

---@param args table
---@return {rounds: {roundNumber: integer, started: boolean, finished:boolean, title: string?, matches: string[]}[],
---opponents: StandingTableOpponentData[],
---bgs: table<integer, string>,
---matches: string[]}
function StandingsParseWiki.parseWikiInput(args)
	---@type {roundNumber: integer, started: boolean, finished:boolean, title: string?, matches: string[]}[]
	local rounds = {}
	for _, roundData, roundIndex in Table.iter.pairsByPrefix(args, 'round', {requireIndex = true}) do
		table.insert(rounds, StandingsParseWiki.parseWikiRound(roundData, roundIndex))
	end

	if Logic.isEmpty(rounds) then
		rounds = {StandingsParseWiki.parseWikiRound(args, 1)}
	end

	local date = DateExt.readTimestamp(args.date) or DateExt.getContextualDateOrNow()

	---@type StandingTableOpponentData[]
	local opponents = Array.map(args, function (opponentData)
		return StandingsParseWiki.parseWikiOpponent(opponentData, #rounds, date)
	end)

	local wrapperMatches = Array.parseCommaSeparatedString(args.matches)
	Array.extendWith(wrapperMatches, Array.flatMap(rounds, function(round)
		return round.matches
	end))

	return {
		rounds = rounds,
		opponents = opponents,
		bgs = StandingsParseWiki.parseWikiBgs(args.bg),
		matches = Array.unique(wrapperMatches),
	}
end

---@param roundInput string|table
---@param roundIndex integer
---@return {roundNumber: integer, started: boolean, finished:boolean, title: string?, matches: string[]}[]
function StandingsParseWiki.parseWikiRound(roundInput, roundIndex)
	local roundData = Json.parseIfString(roundInput)
	local matches = Array.parseCommaSeparatedString(roundData.matches)
	local matchGroups = Array.parseCommaSeparatedString(roundData.matchgroups)
	local stages = Array.parseCommaSeparatedString(roundData.stages)
	if Logic.isNotEmpty(matchGroups) then
		Array.extendWith(matches, Array.flatMap(matchGroups, function(matchGroupId)
			return StandingsParseWiki.getMatchIdsOfMatchGroup(matchGroupId)
		end))
	end
	if Logic.isNotEmpty(stages) then
		Array.extendWith(matches, Array.flatMap(stages, function(stage)
			return StandingsParseWiki.getMatchIdsFromStage(stage)
		end))
	end
	return {
		roundNumber = roundIndex,
		started = Logic.readBool(roundData.started),
		finished = Logic.readBool(roundData.finished),
		title = roundData.title,
		matches = Array.unique(matches),
	}
end

---@param matchGroupId string
---@return string[]
function StandingsParseWiki.getMatchIdsOfMatchGroup(matchGroupId)
	local matchGroup = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(ConditionTree(BooleanOperator.all):add{
			ConditionTree(BooleanOperator.any):add{
				ConditionNode(ColumnName('namespace'), Comparator.eq, 0),
				ConditionNode(ColumnName('namespace'), Comparator.neq, 0),
			},
			ConditionNode(ColumnName('match2bracketid'), Comparator.eq, matchGroupId),
		}),
		query = 'match2id',
		limit = '1000',
	})
	return Array.map(matchGroup, Operator.property('match2id'))
end

---@param rawStage string
---@return string[]
function StandingsParseWiki.getMatchIdsFromStage(rawStage)
	local title = mw.title.new(rawStage)
	assert(title, 'Invalid pagename "' .. rawStage .. '"')
	local namespace, basePage, stage = Logic.nilIfEmpty(title.nsText), title.text, Logic.nilIfEmpty(title.fragment)
	basePage = basePage:gsub(' ', '_')

	local matchGroup = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(ConditionTree(BooleanOperator.all):add(Array.append(
			{ConditionNode(ColumnName('pagename'), Comparator.eq, basePage)},
			namespace and ConditionNode(ColumnName('namespace'), Comparator.eq, Namespace.idFromName(namespace)) or nil,
			stage and ConditionNode(ColumnName('match2bracketdata_sectionheader'), Comparator.eq, stage) or nil
		))),
		query = 'match2id',
		limit = '1000',
	})
	return Array.map(matchGroup, Operator.property('match2id'))
end

---@param opponentInput string|table
---@param numberOfRounds integer
---@param resolveDate string|number?
---@return StandingTableOpponentData[]
function StandingsParseWiki.parseWikiOpponent(opponentInput, numberOfRounds, resolveDate)
	local opponentData = Json.parseIfString(opponentInput)
	local rounds = {}
	for i = 1, numberOfRounds do
		local input = opponentData['r' .. i]
		local points, specialStatus = nil, ''
		if Logic.isNumeric(input) then
			points = tonumber(input)
		elseif input == '-' then
			specialStatus = 'nc'
		else
			specialStatus = input
		end
		local tiebreakerPoints = numberOfRounds == i and tonumber(opponentData.tiebreaker) or nil
		table.insert(rounds, {
			scoreboard = {points = points},
			specialstatus = specialStatus,
			tiebreakerPoints = tiebreakerPoints,
		})
	end

	local opponent = Opponent.readOpponentArgs(opponentData)
	opponent = Opponent.resolve(opponent, resolveDate, {syncPlayer = true})

	return {
		rounds = rounds,
		opponent = opponent,
		startingPoints = opponentData.startingpoints,
	}
end

---@param input string
---@return table<integer, string>
function StandingsParseWiki.parseWikiBgs(input)
	local statusParsed = {}
	Array.forEach(Array.parseCommaSeparatedString(input, ','), function (status)
		local placements, color = unpack(Array.parseCommaSeparatedString(status, '='))
		local pStart, pEnd = unpack(Array.parseCommaSeparatedString(placements, '-'))
		local pStartNumber = tonumber(pStart) --[[@as integer]]
		local pEndNumber = tonumber(pEnd) or pStartNumber
		Array.forEach(Array.range(pStartNumber, pEndNumber), function(placement)
			statusParsed[placement] = color
		end)
	end)
	return statusParsed
end

---@param tabletype StandingsTableTypes
---@param args table
---@return fun(opponent: match2opponent): number|nil
function StandingsParseWiki.makeScoringFunction(tabletype, args)
	if tabletype == 'ffa' then
		if not args['p1'] then
			return function(opponent)
				if opponent.status == 'S' then
					return tonumber(opponent.score)
				end
				return nil
			end
		end
		return function(opponent)
			local scoreFromPlacement = tonumber(args['p' .. opponent.placement])
			return scoreFromPlacement or 0
		end
	elseif tabletype == 'swiss' then
		return function(opponent)
			return opponent.placement == 1 and 1 or 0
		end
	end
	error('Unknown table type')
end

---@param args table
---@param tableType StandingsTableTypes
---@return StandingsTiebreaker[]
function StandingsParseWiki.parseTiebreakers(args, tableType)
	local tiebreakerInput = Json.parseIfString(args.tiebreakers) or {}
	local tiebreakers = {}
	for _, tiebreaker in ipairs(tiebreakerInput) do
		table.insert(tiebreakers, TiebreakerFactory.tiebreakerFromName(tiebreaker))
	end
	if #tiebreakers == 0 then
		if tableType == 'ffa' then
			tiebreakers = {
				TiebreakerFactory.tiebreakerFromName('points'),
				TiebreakerFactory.tiebreakerFromName('manual'),
			}
		elseif tableType == 'swiss' then
			tiebreakers = {
				TiebreakerFactory.tiebreakerFromName('matchdiff'),
				TiebreakerFactory.tiebreakerFromName('manual'),
			}
		end
	end
	return tiebreakers
end

---@param args table
---@param opponents StandingTableOpponentData[]
---@return table?
function StandingsParseWiki.parsePlaceMapping(args, opponents)
	local input = args.placements
	if not input then
		return
	end

	local function placementMappingError(msg)
		error('Invalid placement mapping: "' .. (input or 'nil') .. '" ' .. msg)
	end

	local mapping = {}
	Array.forEach(Array.parseCommaSeparatedString(input, ';'), function (place)
		local places = Array.parseCommaSeparatedString(place, '-')
		local startPlace = tonumber(places[1])
		local placeEnd = tonumber(places[#places])

		if (not startPlace) or (not placeEnd) or (placeEnd < startPlace) or #places > 2 then
			return placementMappingError('Invalid placement range: ' .. place)
		end

		Array.forEach(Array.range(startPlace, placeEnd), function(placeIndex)
			if mapping[placeIndex] then
				return placementMappingError('Duplicate placement mapping: ' .. placeIndex)
			end

			mapping[placeIndex] = startPlace
		end)
	end)

	local numberOfOpponents = #opponents

	if Table.size(mapping) > numberOfOpponents then
		placementMappingError('More placements than opponents: ' .. Table.size(mapping) .. ' > ' .. numberOfOpponents)
	end

	Array.forEach(Array.range(1, numberOfOpponents), function(placeIndex)
		if not mapping[placeIndex] then
			placementMappingError('Missing placement mapping for placement: ' .. placeIndex)
		end
	end)

	return mapping
end

return StandingsParseWiki

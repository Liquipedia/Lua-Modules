---
-- @Liquipedia
-- page=Module:Standings/Table/Legacy/Swiss
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local StandingTable = Lua.import('Module:Standings/Table')
local StandingsParseLpdb = Lua.import('Module:Standings/Parse/Lpdb')
local StandingsParseWiki = Lua.import('Module:Standings/Parse/Wiki')
local TournamentStructure = Lua.import('Module:TournamentStructure')
local Condition = Lua.import('Module:Condition')

local Opponent = Lua.import('Module:Opponent/Custom')

local StandingTableLegacySwiss = {}

local DEFAULT_ROUND_COUNT = 5

local TIEBREAKER_MAPPING_TABLE = {
	points = 'points',
	pts = 'points',
	buchholz = 'buchholz',
	series = 'matchscore',
	diff = 'gamediff',
	['diff games'] = 'gamediff',
	['games won'] = 'gamewins',
	['games loss'] = 'gamelosses',
	['h2h series'] = 'h2hlegacy.matchscore',
	['head-to-head series'] = 'h2hlegacy.matchscore',
	['head to head series'] = 'h2hlegacy.matchscore',
	['h2h games'] = 'h2hlegacy.gamescore',
	['head-to-head games'] = 'h2hlegacy.gamescore',
	['head to head games'] = 'h2hlegacy.gamescore',
	['minileague points'] = 'ml.points',
	['minileague series%'] = 'ml.matchwinrate',
	['minileague games'] = 'ml.gamediff',
	['minileague games won'] = 'ml.gamewins',
}

---@class LegacySwissConfig
---@field tiebreakers table<string, string>? # Overrides of the tiebreaker mapping
---@field bestOfOneTiebreakers table<string, string>? # Translations of the mapped names when every match is a Bo1
---@field adjustParameters (fun(parameters: table, args: table, isBestOfOne: boolean): table)?

---Rainbow Six legacy stores the rounds of a Bo1 as its match score, so its game tiebreakers are round tiebreakers
---@type table<string, string>
StandingTableLegacySwiss.RAINBOWSIX_BEST_OF_ONE_TIEBREAKERS = {
	diff = 'rounddiff',
	['diff games'] = 'rounddiff',
	['games diff'] = 'rounddiff',
	['games won'] = 'roundwins',
	['games loss'] = 'roundlosses',
	['games percentage'] = 'roundwinrate',
	['games%'] = 'roundwinrate',
	['games-percentage'] = 'roundwinrate',
	['h2h games'] = 'h2hlegacy.roundscore',
	['head-to-head games'] = 'h2hlegacy.roundscore',
	['head to head games'] = 'h2hlegacy.roundscore',
	['minileague games'] = 'ml.rounddiff',
	['minileague games won'] = 'ml.roundwins',
}

---Rainbow Six buchholz sums the points of the opponents
---@type LegacySwissConfig
StandingTableLegacySwiss.RAINBOWSIX_CONFIG = {
	tiebreakers = {
		buchholz = 'buchholzpoints',
	},
	bestOfOneTiebreakers = StandingTableLegacySwiss.RAINBOWSIX_BEST_OF_ONE_TIEBREAKERS,
	adjustParameters = function(parameters, args, isBestOfOne)
		if not isBestOfOne then
			return parameters
		end
		-- Legacy counts `walkover_win` as rounds on Bo1
		local adjusted = Table.copy(parameters)
		adjusted.walkovergames = nil
		adjusted.walkoverrounds = Logic.nilIfEmpty(args.walkover_win)
		return adjusted
	end,
}

---@param args table
---@return table
function StandingTableLegacySwiss.getStandardParameter(args)
	return {
		tabletype = 'swiss',
		import = true,
		importopponents = false,
		started = true,
		finished = true,
		exclusive = Logic.nilOr(Logic.readBoolOrNil(args.exclusive), true),
		title = args.title,
		placements = args.placements,
		matchdraws = Logic.readBoolOrNil(args.ties),
		overtime = Logic.readBool(args.show_otp),
		points = StandingTableLegacySwiss.parsePoints(args),
		walkovergames = args.walkover_win,
	}
end

---Maps the legacy `win_p`, `tie_p`, `lose_p`, `X-Y_p`, `walkover_lose_p` and, with `show_otp`, `otw_p` and `otl_p`
---to the `points` input.
---Legacy defaults to 3 points for a win, 1 for a draw and 0 for a loss (2 and 1 for overtime wins and losses),
---and `X-Y_p` is a bonus on top of the points of the result, while `X-Y` in the new input is the fixed amount
---of points. `walkover_lose_p` is a bonus on top of `lose_p` as well.
---@param args table
---@param options {resultDefaults: {w: number, d: number, l: number}?, overtime: boolean?, decimalScores: boolean?}?
---`resultDefaults` defaults to 3, 1 and 0, `overtime` to `show_otp`, and `decimalScores` reads `X-Y_p` with decimals
---@return string
function StandingTableLegacySwiss.parsePoints(args, options)
	options = options or {}
	local resultDefaults = options.resultDefaults or {w = 3, d = 1, l = 0}
	local scorePattern = options.decimalScores and '^(%d+%.?%d*)%-(%d+%.?%d*)_p$' or '^(%d+)%-(%d+)_p$'
	---@param key string
	---@param default number
	---@return number
	local function readPoints(key, default)
		if Logic.isEmpty(args[key]) then
			return default
		end
		return assert(tonumber(args[key]), 'Invalid ' .. key .. ': ' .. args[key])
	end

	local resultPoints = {
		w = readPoints('win_p', resultDefaults.w),
		d = readPoints('tie_p', resultDefaults.d),
		l = readPoints('lose_p', resultDefaults.l),
	}

	local scoreKeys = {}
	for key in pairs(args) do
		if tostring(key):match(scorePattern) then
			table.insert(scoreKeys, key)
		end
	end
	table.sort(scoreKeys)

	local scorePoints = Array.map(scoreKeys, function(key)
		local ownScore, otherScore = key:match(scorePattern)
		local own, other = tonumber(ownScore), tonumber(otherScore)
		local result = own > other and 'w' or own < other and 'l' or 'd'
		return ownScore .. '-' .. otherScore .. '=' .. (resultPoints[result] + readPoints(key, 0))
	end)

	local overtimePoints = Logic.nilOr(options.overtime, Logic.readBool(args.show_otp))
		and {'otwin=' .. readPoints('otw_p', 2), 'otloss=' .. readPoints('otl_p', 1)}
		or {}

	local walkoverLossBonus = readPoints('walkover_lose_p', 0)
	local walkoverLossPoints = walkoverLossBonus ~= 0 and {'walkoverloss=' .. (resultPoints.l + walkoverLossBonus)} or {}

	return table.concat(Array.extend(
		{'win=' .. resultPoints.w, 'draw=' .. resultPoints.d, 'loss=' .. resultPoints.l},
		overtimePoints, walkoverLossPoints, scorePoints
	), ', ')
end

---Matches without maps, like most walkovers, have no best of and don't count
---@param matchRecords {bestof: integer|string?}[]
---@return boolean
function StandingTableLegacySwiss.isBestOfOne(matchRecords)
	local bestOfs = Array.filter(Array.map(matchRecords, function(matchRecord)
		return tonumber(matchRecord.bestof) or 0
	end), function(bestOf) return bestOf > 0 end)
	return #bestOfs > 0 and Array.all(bestOfs, function(bestOf) return bestOf == 1 end)
end

---The matches the standings count, by the opponent, alias and exclusive rules of the import
---@param matchRecords {match2opponents: match2opponent[]?}[]
---@param opponents table[] # Opponent inputs of the standings
---@param parameters {exclusive: boolean?, importopponents: boolean?}
---@return table[]
function StandingTableLegacySwiss.filterCountedMatches(matchRecords, opponents, parameters)
	local date = DateExt.getContextualDateOrNow()
	local manualOpponents = Array.map(opponents, function(opponent)
		return StandingsParseWiki.parseWikiOpponent(opponent, 0, date)
	end)
	local lookupOpponent = StandingsParseLpdb.makeOpponentLookup(manualOpponents, parameters.importopponents)
	local opponentCheck = parameters.exclusive and Array.all or Array.any
	return Array.filter(matchRecords, function(matchRecord)
		return opponentCheck(matchRecord.match2opponents or {}, function(opponentRecord)
			return lookupOpponent(Opponent.fromMatch2Record(opponentRecord)).isPartOfStandings
		end)
	end)
end

---Replaces the mapped tiebreakers that have a translation, other names stay unknown
---@param mapping table<string, string>
---@param translations table<string, string>?
---@return table<string, string>
function StandingTableLegacySwiss.translateTiebreakers(mapping, translations)
	return Table.map(mapping, function(input, tiebreaker)
		return input, (translations or {})[input] or tiebreaker
	end)
end

---Common local Module:SwissTableLeague
---@param frame Frame
---@return Renderable
function StandingTableLegacySwiss.classic(frame)
	return StandingTableLegacySwiss.run(Arguments.getArgs(frame))
end

---Module:SwissTableLeague of rainbowsix
---@param frame Frame
---@return Renderable
function StandingTableLegacySwiss.rainbowsix(frame)
	return StandingTableLegacySwiss.run(Arguments.getArgs(frame), StandingTableLegacySwiss.RAINBOWSIX_CONFIG)
end

---@param args table
---@param config LegacySwissConfig?
---@return Renderable
function StandingTableLegacySwiss.run(args, config)
	config = config or {}
	local roundIndexes = Array.range(1, tonumber(args.rounds) or DEFAULT_ROUND_COUNT)
	local matchesForRound = StandingTableLegacySwiss.mapTournamentInputToMatchesInRounds(args)
	local rounds = Table.map(roundIndexes, function(_, roundIndex)
		return 'round' .. roundIndex, StandingTableLegacySwiss.parseRoundInput(args, roundIndex, matchesForRound[roundIndex])
	end)

	local opponents = Array.mapIndexes(function(teamIndex)
		if args.opptype == 'solo' then
			return StandingTableLegacySwiss.parseSoloInput(args, teamIndex)
		end
		return StandingTableLegacySwiss.parseTeamInput(args, teamIndex)
	end)

	local bgs = StandingTableLegacySwiss.parseWikiBgs(args, 'pbg')

	local parameters = StandingTableLegacySwiss.getStandardParameter(args)
	-- Only the Bo1 translation needs the format, from the matches the standings count
	local isBestOfOne = config.bestOfOneTiebreakers ~= nil and StandingTableLegacySwiss.isBestOfOne(
		StandingTableLegacySwiss.filterCountedMatches(Array.flatMap(roundIndexes, function(roundIndex)
			return matchesForRound[roundIndex] or {}
		end), opponents, parameters)
	)
	local tiebreakers = StandingTableLegacySwiss.parseTiebreaker(args, config, isBestOfOne)
	if config.adjustParameters then
		parameters = config.adjustParameters(parameters, args, isBestOfOne)
	end

	return StandingTable.fromTemplate(Table.merge(parameters, {bg = bgs}, rounds, opponents, {tiebreakers = tiebreakers}))
end

---@param args table
---@param roundIndex integer
---@param matches {id: string}[]
---@return {title: string, started: boolean, finished: boolean, matches: string}
function StandingTableLegacySwiss.parseRoundInput(args, roundIndex, matches)
	local title = (args.roundtitle or 'Round') .. ' ' .. roundIndex
	return {
		title = title,
		-- Legacy, so let's assume finished
		started = true,
		finished = true,
		matches = table.concat(Array.map(matches or {}, Operator.property('id')), ','),
	}
end

---@param args table
---@param index integer
---@return string?, string?, string?
local function parseCoreInput(args, index)
	local tiebreaker = args['temp_tie' .. index]
	local points = args['temp_p' .. index]
	local dq = args['dq' .. index]
	return tiebreaker, points, dq
end

---Legacy `r<round>bg<index>` maps to `r<round>bg` on the opponent
---@param args table
---@param index integer
---@return table<string, string>
local function parseDefiniteStatuses(args, index)
	return Table.map(Array.range(1, tonumber(args.rounds) or DEFAULT_ROUND_COUNT), function(roundIndex)
		return 'r' .. roundIndex .. 'bg', args['r' .. roundIndex .. 'bg' .. index]
	end)
end

---Legacy `team<index>alias` is a comma separated list of team templates
---@param args table
---@param teamIndex integer
---@return {type: OpponentType, [1]: string, tiebreaker: string?, r1points: string?, dq: string?,
---aliases: string?, r1bg: string?}?
function StandingTableLegacySwiss.parseTeamInput(args, teamIndex)
	local team = args['team' .. teamIndex]
	if not team then
		return nil
	end

	local tiebreaker, points, dq = parseCoreInput(args, teamIndex)
	local aliases = args['team' .. teamIndex .. 'alias']

	return Table.merge({
		type = Opponent.team,
		team,
		tiebreaker = tiebreaker,
		r1points = points,
		dq = dq,
		aliases = aliases and table.concat(Array.parseCommaSeparatedString(aliases), ';') or nil,
	}, parseDefiniteStatuses(args, teamIndex))
end

---@param args table
---@param playerIndex integer
---@return {type: OpponentType, [1]: string, tiebreaker: string?, r1points: string?, dq: string?, r1bg: string?}?
function StandingTableLegacySwiss.parseSoloInput(args, playerIndex)
	local player = args['player' .. playerIndex] or args['p' .. playerIndex]
	if not player then
		return nil
	end

	local tiebreaker, points, dq = parseCoreInput(args, playerIndex)

	return Table.merge({
		type = Opponent.solo,
		player,
		flag = args['player' .. playerIndex .. 'flag'] or args['p' .. playerIndex .. 'flag'],
		link = args['player' .. playerIndex .. 'link'] or args['p' .. playerIndex .. 'link'],
		tiebreaker = tiebreaker,
		r1points = points,
		dq = dq,
	}, parseDefiniteStatuses(args, playerIndex))
end

---@param args table
---@param prefix 'bg'|'pbg'
---@return string
function StandingTableLegacySwiss.parseWikiBgs(args, prefix)
	local bgs = {}
	for _, value, index in Table.iter.pairsByPrefix(args, prefix, {requireIndex = true}) do
		table.insert(bgs, index .. '=' .. value)
	end
	return table.concat(bgs, ',')
end

---@param args table
---@param config LegacySwissConfig?
---@param isBestOfOne boolean?
---@return string[]
function StandingTableLegacySwiss.parseTiebreaker(args, config, isBestOfOne)
	config = config or {}
	local mapping = Table.merge(TIEBREAKER_MAPPING_TABLE, config.tiebreakers)
	if isBestOfOne then
		mapping = StandingTableLegacySwiss.translateTiebreakers(mapping, config.bestOfOneTiebreakers)
	end
	local tiebreakers = {}
	for _, value in Table.iter.pairsByPrefix(args, 'tiebreaker', {requireIndex = true}) do
		local mappedTiebreaker = mapping[value]
		assert(mappedTiebreaker, 'Unknown tiebreaker: ' .. value)
		table.insert(tiebreakers, mappedTiebreaker)
	end
	return tiebreakers
end

---@param args table
---@return table<integer, {id: string, bestof: integer?, match2opponents: match2opponent[]?}[]>
function StandingTableLegacySwiss.mapTournamentInputToMatchesInRounds(args)
	local tournamentStructureSpec = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec()
	local match2Filter = TournamentStructure.getMatch2Filter(tournamentStructureSpec)
	local conditions = Condition.Tree(Condition.BooleanOperator.all):add(match2Filter)

	local sdate, edate = DateExt.readTimestampOrNil(args.sdate), DateExt.readTimestampOrNil(args.edate)
	if sdate then
		conditions:add(Condition.Node(Condition.ColumnName('date'), Condition.Comparator.ge, sdate))
	end
	if edate then
		conditions:add(Condition.Node(Condition.ColumnName('date'), Condition.Comparator.le, edate))
	end

	local matches = mw.ext.LiquipediaDB.lpdb('match2',
		{
			conditions = tostring(conditions),
			query = 'match2id, bestof, extradata, match2opponents',
			limit = 1000,
		}
	)

	matches = Array.map(matches, function(match)
		local roundText = match.extradata.matchsection or ''
		return {
			id = match.match2id,
			round = tonumber(string.match(roundText, 'Round%s*(%d+)')),
			bestof = tonumber(match.bestof),
			match2opponents = match.match2opponents,
		}
	end)
	if Array.all(matches, function(match) return match.round == nil end) then
		mw.ext.TeamLiquidIntegration.add_category('Pages with missing matches in swiss table')
	end
	local _, matchesByRound = Array.groupBy(matches, function(match)
		return match.round
	end)
	return matchesByRound
end

return StandingTableLegacySwiss

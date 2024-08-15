---
-- @Liquipedia
-- wiki=dota2
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')
local Streams = require('Module:Links/Stream')
local HeroNames = mw.loadData('Module:HeroNames')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local Opponent = Lua.import('Module:Opponent')

local STATUS_SCORE = 'S'
local STATUS_DRAW = 'D'
local STATUS_DEFAULT_WIN = 'W'
local STATUS_FORFEIT = 'FF'
local STATUS_DISQUALIFIED = 'DQ'
local STATUS_DEFAULT_LOSS = 'L'
local ALLOWED_STATUSES = {
	STATUS_DRAW,
	STATUS_DEFAULT_WIN,
	STATUS_FORFEIT,
	STATUS_DISQUALIFIED,
	STATUS_DEFAULT_LOSS,
}
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_PLAYERS = 15
local DEFAULT_BESTOF = 3
local DEFAULT_MODE = 'team'
local DEFAULT_GAME = 'dota2'
local NO_SCORE = -99
local DUMMY_MAP = 'default'
local NP_STATUSES = {'skip', 'np', 'canceled', 'cancelled'}
local DEFAULT_RESULT_TYPE = 'default'
local NOT_PLAYED_SCORE = -1
local NO_WINNER = -1
local MIN_EARNINGS_FOR_FEATURED = 100000

local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

---@class Dota2MatchParserInterface
---@field getMap fun(mapInput: table): table
---@field getLength fun(map: table): string?
---@field getSide fun(map: table, opponentIndex: integer): string?
---@field getObjectives fun(map: table, opponentIndex: integer): string?
---@field getHeroPicks fun(map: table, opponentIndex: integer): string[]?
---@field getHeroBans fun(map: table, opponentIndex: integer): string[]?
---@field getParticipants fun(map: table, opponentIndex: integer): table[]?
---@field getVetoPhase fun(map: table): table?

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@param options? {isMatchPage: boolean?}
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	options = options or {}

	local MatchParser
	if options.isMatchPage then
		MatchParser = Lua.import('Module:MatchGroup/Input/Custom/MatchPage')
	else
		MatchParser = Lua.import('Module:MatchGroup/Input/Custom/Normal')
	end

	-- process match
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))

	if not options.isMatchPage then
		--set it already here so in winner and result type processing we know it will get enriched later on
		local standaloneMatchId = match.matchid and match.bracketid
			and ('MATCH_' .. match.bracketid .. '_' .. match.matchid)
			or nil
		match.standaloneMatch = standaloneMatchId and MatchGroupInput.fetchStandaloneMatch(standaloneMatchId) or nil
	end

	match = MatchFunctions.getBestOf(match)
	match = MatchFunctions.adjustMapData(MatchParser, match)
	match = MatchFunctions.getScoreFromMapWinners(match)
	match = MatchFunctions.getOpponents(match)
	match = MatchFunctions.getTournamentVars(match)
	match = MatchFunctions.getVodStuff(match)
	match = MatchFunctions.getPublisherId(match)
	match = MatchFunctions.getLinks(match)
	match = MatchFunctions.getExtraData(match)

	if not options.isMatchPage then
		match = MatchFunctions.mergeWithStandalone(match)
	end

	return match
end

---@param MatchParser Dota2MatchParserInterface
---@param match table
---@return table
function MatchFunctions.adjustMapData(MatchParser, match)
	local opponents = Array.mapIndexes(function(idx) return match['opponent' .. idx] end)

	for key, mapInput in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local map = MatchParser.getMap(mapInput)

		if map.map == DUMMY_MAP then
			map.map = nil
		end
		map.length = MatchParser.getLength(map)
		map = MapFunctions.getParticipants(MatchParser, map, opponents)
		map = MapFunctions.getScoresAndWinner(map)

		match[key] = map
	end

	return match
end

CustomMatchGroupInput.processMap = FnUtil.identity

---@param record table
---@param timestamp integer
function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if Opponent.isBye(opponent) then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	---@type number|string
	local teamTemplateDate = timestamp
	-- If date is default date, resolve using tournament dates instead
	-- default date indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not the default date
	if teamTemplateDate == DateExt.defaultTimestamp then
		teamTemplateDate = Variables.varDefaultMulti('tournament_enddate', 'tournament_startdate', NOW)
	end

	Opponent.resolve(opponent, teamTemplateDate, {syncPlayer = true})
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

---@param data table
---@param indexedScores table[]
---@return table
---@return table[]
function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	-- Map or Match wasn't played, set not played
	if
		Table.includes(NP_STATUSES, data.finished) or
		Table.includes(NP_STATUSES, data.winner)
	then
		data.resulttype = 'np'
		data.finished = true
	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	elseif Logic.readBool(data.finished) then
		if MatchGroupInput.isDraw(indexedScores) then
			data.winner = 0
			data.resulttype = 'draw'
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 'draw')
		elseif CustomMatchGroupInput.placementCheckSpecialStatus(indexedScores) then
			data.winner = CustomMatchGroupInput.getDefaultWinner(indexedScores)
			data.resulttype = DEFAULT_RESULT_TYPE
			if CustomMatchGroupInput.placementCheckFF(indexedScores) then
				data.walkover = 'ff'
			elseif CustomMatchGroupInput.placementCheckDQ(indexedScores) then
				data.walkover = 'dq'
			elseif CustomMatchGroupInput.placementCheckWL(indexedScores) then
				data.walkover = 'l'
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, DEFAULT_RESULT_TYPE)
		else
			local winner
			indexedScores, winner = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, nil, data.finished)
			data.winner = data.winner or winner
		end
	end

	-- set it as finished if we have a winner
	if not Logic.isEmpty(data.winner) then
		data.finished = true
	end

	return data, indexedScores
end

---@param opponents table[]
---@param winner integer?
---@param specialType string?
---@param finished boolean?
---@return table[]
---@return integer?
function CustomMatchGroupInput.setPlacement(opponents, winner, specialType, finished)
	if specialType == 'draw' then
		for key, _ in pairs(opponents) do
			opponents[key].placement = 1
		end
	elseif specialType == DEFAULT_RESULT_TYPE then
		for key, _ in pairs(opponents) do
			if key == winner then
				opponents[key].placement = 1
			else
				opponents[key].placement = 2
			end
		end
	else
		local lastScore = NO_SCORE
		local lastPlacement = NO_SCORE
		local counter = 0
		for scoreIndex, opp in Table.iter.spairs(opponents, CustomMatchGroupInput.placementSortFunction) do
			local score = tonumber(opp.score)
			counter = counter + 1
			if counter == 1 and (winner or '') == '' then
				if finished then
					winner = scoreIndex
				end
			end
			if lastScore == score then
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement or '') or lastPlacement
			else
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement or '') or counter
				lastPlacement = counter
				lastScore = score or NO_SCORE
			end
		end
	end

	return opponents, winner
end

---@param tbl table[]
---@param key1 integer
---@param key2 integer
---@return boolean
function CustomMatchGroupInput.placementSortFunction(tbl, key1, key2)
	local value1 = tonumber(tbl[key1].score or NO_SCORE) or NO_SCORE
	local value2 = tonumber(tbl[key2].score or NO_SCORE) or NO_SCORE
	return value1 > value2
end

-- Check if any opponent has a none-standard status
---@param tbl table
---@return boolean
function CustomMatchGroupInput.placementCheckSpecialStatus(tbl)
	return Table.any(tbl,
		function (_, scoreinfo)
			return scoreinfo.status ~= STATUS_SCORE and String.isNotEmpty(scoreinfo.status)
		end
	)
end

-- function to check for forfeits
---@param tbl table
---@return boolean
function CustomMatchGroupInput.placementCheckFF(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status == STATUS_FORFEIT end)
end

-- function to check for DQ's
---@param tbl table
---@return boolean
function CustomMatchGroupInput.placementCheckDQ(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status == STATUS_DISQUALIFIED end)
end

-- function to check for W/L
---@param tbl table
---@return boolean
function CustomMatchGroupInput.placementCheckWL(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status == STATUS_DEFAULT_LOSS end)
end

-- Get the winner when resulttype=default
---@param tbl table
---@return integer
function CustomMatchGroupInput.getDefaultWinner(tbl)
	for index, scoreInfo in pairs(tbl) do
		if scoreInfo.status == STATUS_DEFAULT_WIN then
			return index
		end
	end
	return NO_WINNER
end

--
-- match related functions
--

---@param match table
---@return table
function MatchFunctions.getBestOf(match)
	match.bestof = Logic.emptyOr(match.bestof, Variables.varDefault('bestof', DEFAULT_BESTOF))
	Variables.varDefine('bestof', match.bestof)
	return match
end

-- Calculate the match scores based on the map results (counting map wins)
-- Only update an opponents result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
---@param match table
---@return table
function MatchFunctions.getScoreFromMapWinners(match)
	local newScores = {}
	local setScores = false

	-- If the match has started, we want to use the automatic calculations
	if match.dateexact then
		if match.timestamp <= NOW then
			setScores = true
		end
	end

	local mapIndex = 1
	while match['map'..mapIndex] do
		local winner = tonumber(match['map'..mapIndex].winner)
		if winner and winner > 0 and winner <= MAX_NUM_OPPONENTS then
			setScores = true
			newScores[winner] = (newScores[winner] or 0) + 1
		end
		mapIndex = mapIndex + 1
	end

	for index = 1, MAX_NUM_OPPONENTS do
		if not match['opponent' .. index].score and setScores then
			match['opponent' .. index].score = newScores[index] or 0
		end
	end

	return match
end

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	match.headtohead = Logic.emptyOr(match.headtohead, Variables.varDefault('headtohead'))

	-- needed due to DEFAULT_GAME
	match.game = Logic.emptyOr(match.game, Variables.varDefault('tournament_game', DEFAULT_GAME))

	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function MatchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)

	for _, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local vodgame = match['vodgame' .. mapIndex]
		map.vod = map.vod or vodgame
	end

	return match
end

---@param match table
---@return table
function MatchFunctions.getPublisherId(match)
	for _, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local publisherid = match['matchid' .. mapIndex]
		map.publisherid = map.matchid or publisherid
	end

	return match
end

---@param match table
---@return table
function MatchFunctions.getLinks(match)
	match.links = {
		preview = match.preview,
		lrthread = match.lrthread,
		recap = match.recap,
		stratz = {},
		dotabuff = {},
		datdota = {},
	}
	if match.faceit then match.links.faceit = 'https://www.faceit.com/en/dota2/room/' .. match.faceit end

	for _, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		if map.publisherid then
			match.links.stratz[mapIndex] = 'https://stratz.com/match/' .. map.publisherid
			match.links.dotabuff[mapIndex] = 'https://www.dotabuff.com/matches/' .. map.publisherid
			match.links.datdota[mapIndex] = 'https://www.datdota.com/matches/' .. map.publisherid
		end
	end
	return match
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	match.extradata = {
		featured = tostring(Logic.emptyOr(
			match.featured,
			MatchFunctions.isFeatured(match),
			''
		)),
		mvp = MatchGroupInput.readMvp(match),
		headtohead = match.headtohead,
	}
	return match
end

---@param match table
---@return boolean
function MatchFunctions.isFeatured(match)
	local tier = tonumber(match.liquipediatier or '')
	if tier == 1 or tier == 2 then
		return true
	end

	local opponent1, opponent2 = match.opponent1, match.opponent2
	local year, month = match.date:match('^(%d%d%d%d)-(%d%d)')
	if year == DateExt.defaultYear then
		return false
	end
	if tonumber(month) < 3 then
		year = tonumber(year) - 1
	end

	if
		opponent1.type == Opponent.team and
		MatchFunctions.getEarnings(opponent1.name, year) >= MIN_EARNINGS_FOR_FEATURED
	or
		opponent2.type == Opponent.team and
		MatchFunctions.getEarnings(opponent2.name, year) >= MIN_EARNINGS_FOR_FEATURED
	then
		return true
	end

	return false
end

---@param name string
---@param year integer
---@return number?
function MatchFunctions.getEarnings(name, year)
	if String.isEmpty(name) then
		return 0
	end

	if String.isNotEmpty(Variables.varDefault(name .. '_featured_earnings')) then
		return tonumber(Variables.varDefault(name .. '_featured_earnings'))
	end

	local data = mw.ext.LiquipediaDB.lpdb('team', {
		conditions = '[[pagename::' .. name:gsub(' ', '_') .. ']]',
		query = 'extradata'
	})

	local currentEarnings = 0
	if type(data[1]) == 'table' then
		currentEarnings = tonumber((data[1].extradata or {})['earningsin' .. year] or 0) or 0
	end

	Variables.varDefine(name .. '_featured_earnings', currentEarnings)

	return currentEarnings
end

---@param match table
---@return table
function MatchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

			-- apply status
			opponent.score = string.upper(opponent.score or '')
			if Logic.isNumeric(opponent.score) then
				opponent.score = tonumber(opponent.score)
				opponent.status = STATUS_SCORE
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = NOT_PLAYED_SCORE
			end

			-- get players from vars for teams
			if opponent.type == Opponent.team then
				if not Logic.isEmpty(opponent.name) then
					match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name, {
						resolveRedirect = true,
						applyUnderScores = true,
						maxNumPlayers = MAX_NUM_PLAYERS,
					})
				end
			elseif opponent.type ~= Opponent.solo and opponent.type ~= Opponent.literal then
				error('Unsupported Opponent Type "' .. (opponent.type or '') .. '"')
			end

			opponents[opponentIndex] = opponent
		end
	end

	--apply walkover input
	match.walkover = string.upper(match.walkover or '')
	if Logic.isNumeric(match.walkover) then
		local winnerIndex = tonumber(match.walkover)
		opponents = MatchFunctions._makeAllOpponentsLoseByWalkover(opponents, STATUS_DEFAULT_LOSS)
		opponents[winnerIndex].status = STATUS_DEFAULT_WIN
		match.finished = true
	elseif Logic.isNumeric(match.winner) and Table.includes(ALLOWED_STATUSES, match.walkover) then
		local winnerIndex = tonumber(match.winner)
		opponents = MatchFunctions._makeAllOpponentsLoseByWalkover(opponents, match.walkover)
		opponents[winnerIndex].status = STATUS_DEFAULT_WIN
		match.finished = true
	end

	-- see if match should actually be finished if bestof limit was reached
	if isScoreSet and not Logic.readBool(match.finished) then
		local firstTo = math.floor(match.bestof / 2)
		for _, item in pairs(opponents) do
			if tonumber(item.score or 0) > firstTo then
				match.finished = true
				break
			end
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.timestamp ~= DateExt.defaultTimestamp then
		local threshold = match.dateexact and 30800 or 86400
		if match.timestamp + threshold < NOW then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	if
		not Logic.isEmpty(match.winner) or
		Logic.readBool(match.finished) or
		CustomMatchGroupInput.placementCheckSpecialStatus(opponents)
	then
		match.finished = true
		match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
	end

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end
	return match
end

---@param opponents table[]
---@param walkoverType string?
---@return table[]
function MatchFunctions._makeAllOpponentsLoseByWalkover(opponents, walkoverType)
	for index, _ in pairs(opponents) do
		opponents[index].score = NOT_PLAYED_SCORE
		opponents[index].status = walkoverType
	end
	return opponents
end

---@param match table
---@return table
function MatchFunctions.mergeWithStandalone(match)
	local standaloneMatch = match.standaloneMatch
	if not standaloneMatch then
		return match
	end

	match.matchPage = 'Match:ID_' .. match.bracketid .. '_' .. match.matchid

	-- Update Opponents from the Standlone Match
	match.opponent1 = standaloneMatch.match2opponents[1]
	match.opponent2 = standaloneMatch.match2opponents[2]

	-- Update Maps from the Standalone Match
	for index, game in ipairs(standaloneMatch.match2games) do
		game.participants = Json.parseIfString(game.participants)
		game.extradata = Json.parseIfString(game.extradata)
		match['map' .. index] = game
	end

	-- Remove special keys (maps/games, opponents, bracketdata etc)
	for key, _ in pairs(standaloneMatch) do
		if String.startsWith(key, 'match2') then
			standaloneMatch[key] = nil
		end
	end

	-- Copy all match level records which have value
	for key, value in pairs(standaloneMatch) do
		if String.isNotEmpty(value) then
			match[key] = value
		end
	end

	return match
end

--
-- map related functions
--

-- Parse extradata information
---@param MatchParser Dota2MatchParserInterface
---@param map table
---@return table
function MapFunctions.getAdditionalExtraData(MatchParser, map)
	map.extradata.comment = map.comment
	map.extradata.team1side = MatchParser.getSide(map, 1) or ''
	map.extradata.team2side = MatchParser.getSide(map, 2) or ''
	map.extradata.team1objectives = MatchParser.getObjectives(map, 1) or {}
	map.extradata.team2objectives = MatchParser.getObjectives(map, 2) or {}
	map.extradata.publisherid = map.publisherid or ''

	return map
end

-- Parse participant information
---@param MatchParser Dota2MatchParserInterface
---@param map table
---@param opponents table[]
---@return table
function MapFunctions.getParticipants(MatchParser, map, opponents)
	local participants = {}
	local extradata = {}
	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, HeroNames)

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local teamPrefix = 'team' .. opponentIndex
		Array.forEach(MatchParser.getHeroPicks(map, opponentIndex) or {}, function (hero, idx)
			extradata[teamPrefix .. 'hero' .. idx] = getCharacterName(hero)
		end)
		Array.forEach(MatchParser.getHeroBans(map, opponentIndex) or {}, function (hero, idx)
			extradata[teamPrefix .. 'ban' .. idx] = getCharacterName(hero)
		end)
		for playerIndex, participant in ipairs(MatchParser.getParticipants(map, opponentIndex) or {}) do
			participant.character = getCharacterName(participant.character)
			participants[opponentIndex .. '_' .. playerIndex] = participant
		end
	end

	extradata.vetophase = MatchParser.getVetoPhase(map)
	Array.forEach(extradata.vetophase or {}, function(veto)
		veto.character = getCharacterName(veto.character)
	end)

	map.participants = participants
	map.extradata = extradata

	return MapFunctions.getAdditionalExtraData(MatchParser, map)
end

-- Calculate Score and Winner of the map
---@param map table
---@return table
function MapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex] or map['t' .. scoreIndex .. 'score']
		local obj = {}
		if not Logic.isEmpty(score) then
			if Logic.isNumeric(score) then
				obj.status = STATUS_SCORE
				score = tonumber(score)
				map['score' .. scoreIndex] = score
				obj.score = score
			elseif Table.includes(ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = NOT_PLAYED_SCORE
			end
			table.insert(map.scores, score)
			indexedScores[scoreIndex] = obj
		else
			break
		end
	end

	map = CustomMatchGroupInput.getResultTypeAndWinner(map, indexedScores)

	return map
end

return CustomMatchGroupInput

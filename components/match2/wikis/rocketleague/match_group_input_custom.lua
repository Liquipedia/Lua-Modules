---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchGroupInput = {}

local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')

local DEFAULT_MODE = '3v3'

local EARNINGS_LIMIT_FOR_FEATURED = 10000
local CURRENT_YEAR = os.date('%Y')

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, {})
	end)
	local games = CustomMatchGroupInput.extractMaps(match, #opponents)

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.extradata = CustomMatchGroupInput.getOpponentExtradata(opponent)
		if opponent.extradata.additionalScores then
			opponent.score = CustomMatchGroupInput._getSetWins(opponent)
		end
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		})
	end)

	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInputUtil.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInputUtil.getWinner(match.resulttype, winnerInput, opponents)
		MatchGroupInputUtil.setPlacement(opponents, match.winner, 1, 2)
	elseif MatchGroupInputUtil.isNotPlayed(winnerInput, finishedInput) then
		match.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponents)
		match.winner = nil
	end

	MatchFunctions.getTournamentVars(match)

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match)

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(match, opponents)

	return match
end

---@param match table
---@param opponentCount integer
---@return table
function CustomMatchGroupInput.extractMaps(match, opponentCount)
	local maps = {}
	for key, map, mapIndex in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = MapFunctions.getExtraData(map)
		map.vod = map.vod or String.nilIfEmpty(match['vodgame' .. mapIndex])
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))

		if Logic.readBoolOrNil(finishedInput) == nil and Logic.isNotEmpty(map.scores) then
			map.finished = true
		end

		if map.finished or MatchGroupInputUtil.isNotPlayed(map.winner, finishedInput) then
			map.resulttype = MatchGroupInputUtil.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInputUtil.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInputUtil.getWinner(map.resulttype, winnerInput, opponentInfo)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

CustomMatchGroupInput.processMap = FnUtil.identity

---@param opponent table
---@return table?
function CustomMatchGroupInput.getOpponentExtradata(opponent)
	if not Logic.isNumeric(opponent.score2) then
		return {}
	end

	return {
		score1 = tonumber(opponent.score),
		score2 = tonumber(opponent.score2),
		score3 = tonumber(opponent.score3),
		set1win = Logic.readBool(opponent.set1win),
		set2win = Logic.readBool(opponent.set2win),
		set3win = Logic.readBool(opponent.set3win),
		additionalScores = true
	}
end

---@param opponent table
---@return integer
function CustomMatchGroupInput._getSetWins(opponent)
	local extradata = opponent.extradata
	local set1win = extradata.set1win and 1 or 0
	local set2win = extradata.set2win and 1 or 0
	local set3win = extradata.set3win and 1 or 0
	return set1win + set2win + set3win
end

--
-- match related functions
--

---@param match table
---@return table
function MatchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', DEFAULT_MODE))
	return MatchGroupInputUtil.getCommonTournamentVars(match)
end

---@param match table
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, opponents)
	local opponent1 = opponents[1]
	local opponent2 = opponents[2]

	local showh2h = Logic.readBool(Logic.emptyOr(match.showh2h, Variables.varDefault('showh2h')))
		and opponent1.type == Opponent.team
		and opponent2.type == Opponent.team

	return {
		showh2h = showh2h,
		isfeatured = MatchFunctions.isFeatured(opponents, tonumber(match.liquipediatier)),
		casters = MatchGroupInputUtil.readCasters(match),
		hasopponent1 = MatchFunctions._checkForNonEmptyOpponent(opponent1),
		hasopponent2 = MatchFunctions._checkForNonEmptyOpponent(opponent2),
		liquipediatiertype2 = Variables.varDefault('tournament_tiertype2'),
	}
end

---@param opponent table
---@return boolean
function MatchFunctions._checkForNonEmptyOpponent(opponent)
	if Opponent.typeIsParty(opponent.type) then
		return not Array.all(opponent.match2players, Opponent.playerIsTbd)
	end
	-- Literal and Teams can use the default function, player's can not because of match2player vs player list names
	return not Opponent.isTbd(opponent)
end

---@param match table
---@return table
function MatchFunctions.getLinks(match)
	local links = {}

	-- Shift (formerly Octane)
	for key, shift in Table.iter.pairsByPrefix(match, 'shift', {requireIndex = false}) do
		links[key] = 'https://www.shiftrle.gg/matches/' .. shift
	end

	-- Ballchasing
	for key, ballchasing in Table.iter.pairsByPrefix(match, 'ballchasing', {requireIndex = false}) do
		links[key] = 'https://ballchasing.com/group/' .. ballchasing
	end

	return links
end

---@param opponents table[]
---@param tier integer?
---@return boolean
function MatchFunctions.isFeatured(opponents, tier)
	local opponent1 = opponents[1]
	local opponent2 = opponents[2]
	if opponent1.type ~= Opponent.team or opponent2.type ~= Opponent.team then
		return false
	end

	if
		tier == 1
		or tier == 2
		or Logic.readBool(Variables.varDefault('tournament_rlcs_premier'))
		or not String.isEmpty(Variables.varDefault('match_featured_override'))
	then
		return true
	end

	return MatchFunctions.currentEarnings(opponent1.name) >= EARNINGS_LIMIT_FOR_FEATURED
		or MatchFunctions.currentEarnings(opponent2.name) >= EARNINGS_LIMIT_FOR_FEATURED
end

---@param name string?
---@return integer
function MatchFunctions.currentEarnings(name)
	if String.isEmpty(name) then
		return 0
	end
	local data = mw.ext.LiquipediaDB.lpdb('team', {
		conditions = '[[name::' .. name .. ']]',
		query = 'extradata'
	})[1]

	if not data then
		return 0
	end

	local currentEarnings = (data.extradata or {})['earningsin' .. CURRENT_YEAR]
	return tonumber(currentEarnings) or 0
end

--
-- map related functions
--

---@param map table
---@return table
function MapFunctions.getExtraData(map)
	local timeouts = Array.extractValues(Table.mapValues(mw.text.split(map.timeout or '', ','), tonumber))

	return {
		ot = map.ot,
		otlength = map.otlength,
		comment = map.comment,
		header = map.header,
		--the following is used to store 'mapXtYgoals' from LegacyMatchLists
		t1goals = map.t1goals,
		t2goals = map.t2goals,
		timeout = Table.isNotEmpty(timeouts) and Json.stringify(timeouts) or nil,
	}
end

return CustomMatchGroupInput

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

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
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

	Table.mergeInto(match, MatchGroupInput.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInput.readOpponent(match, opponentIndex, {})
	end)
	local games = CustomMatchGroupInput.extractMaps(match, #opponents)

	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.extradata = CustomMatchGroupInput.getOpponentExtradata(opponent)
		if opponent.extradata.additionalScores then
			opponent.score = CustomMatchGroupInput._getSetWins(opponent)
		end
		opponent.score, opponent.status = MatchGroupInput.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		})
	end)

	match.finished = MatchGroupInput.matchIsFinished(match, opponents)

	if match.finished then
		match.resulttype = MatchGroupInput.getResultType(winnerInput, finishedInput, opponents)
		match.walkover = MatchGroupInput.getWalkover(match.resulttype, opponents)
		match.winner = MatchGroupInput.getWinner(match.resulttype, winnerInput, opponents)
		MatchGroupInput.setPlacement(opponents, match.winner, 1, 2)
	end

	MatchFunctions.getTournamentVars(match)

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match)

	match.extradata = MatchFunctions.getExtraData(match)

	match.games = games
	match.opponents = opponents

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
		map.finished = MatchGroupInput.mapIsFinished(map)

		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInput.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.resulttype = MatchGroupInput.getResultType(winnerInput, finishedInput, opponentInfo)
			map.walkover = MatchGroupInput.getWalkover(map.resulttype, opponentInfo)
			map.winner = MatchGroupInput.getWinner(map.resulttype, winnerInput, opponentInfo)
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
	match.showh2h = Logic.emptyOr(match.showh2h, Variables.varDefault('showh2h'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function MatchFunctions.getExtraData(match)
	local opponent1 = match.opponent1 or {}
	local opponent2 = match.opponent2 or {}

	local showh2h = Logic.readBool(match.showh2h)
		and opponent1.type == Opponent.team
		and opponent2.type == Opponent.team

	return {
		showh2h = showh2h,
		isfeatured = MatchFunctions.isFeatured(match),
		casters = MatchGroupInput.readCasters(match),
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
	elseif opponent.type == Opponent.team then
		return not Opponent.isTbd(opponent.template)
	end

	-- Literal case
	return false
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

---@param match table
---@return boolean
function MatchFunctions.isFeatured(match)
	local opponent1 = match.opponent1
	local opponent2 = match.opponent2
	if opponent1.type ~= Opponent.team or opponent2.type ~= Opponent.team then
		return false
	end

	if
		tonumber(match.liquipediatier) == 1
		or tonumber(match.liquipediatier) == 2
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

	if not data[1] then
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
		timeout = Table.isNotEmpty(timeouts) and Json.stringify(timeouts) or nil,
		--the following is used to store 'mapXtYgoals' from LegacyMatchLists
		t1goals = map.t1goals,
		t2goals = map.t2goals,
	}
end

return CustomMatchGroupInput

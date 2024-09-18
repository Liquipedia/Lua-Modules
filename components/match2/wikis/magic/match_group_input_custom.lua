---
-- @Liquipedia
-- wiki=magic
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input/Util')
local Streams = Lua.import('Module:Links/Stream')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local UNKNOWN_REASON_LOSS_STATUS = 'L'
local DEFAULT_WIN_STATUS = 'W'
local DEFAULT_WIN_RESULTTYPE = 'default'
local NO_SCORE = -1
local SCORE_STATUS = 'S'
local ALLOWED_STATUSES = {DEFAULT_WIN_STATUS, 'FF', 'DQ', UNKNOWN_REASON_LOSS_STATUS}
local MAX_NUM_OPPONENTS = 2
local DEFAULT_BEST_OF = 99
local NOW = os.time(os.date('!*t')--[[@as osdateparam]])
local BYE = 'BYE'
local MAX_NUM_MAPS = 30

local CustomMatchGroupInput = {}

CustomMatchGroupInput.walkoverProcessing = {}
local walkoverProcessing = CustomMatchGroupInput.walkoverProcessing

-- called from Module:MatchGroup
---@param match table
---@return table
function CustomMatchGroupInput.processMatch(match)
	if Logic.readBool(match.ffa) then
		error('FFA matches are not yet supported')
		-- later call ffa processing from here
	elseif match['opponent' .. (MAX_NUM_OPPONENTS + 1)] then
		error('Unexpected number of opponents in a non-FFA match')
	end

	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = CustomMatchGroupInput._getExtraData(match)
	match = CustomMatchGroupInput._getTournamentVars(match)
	match = CustomMatchGroupInput._adjustData(match)
	match = CustomMatchGroupInput._getVodStuff(match)

	return match
end

---@param match any
---@return table
function CustomMatchGroupInput._getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'solo'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match any
---@return table
function CustomMatchGroupInput._getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod)

	return match
end

---@param match any
---@return table
function CustomMatchGroupInput._getExtraData(match)
	match.extradata = {}

	for subGroupIndex = 1, MAX_NUM_MAPS do
		local prefix = 'subgroup' .. subGroupIndex

		match.extradata[prefix .. 'header'] = CustomMatchGroupInput._getSubGroupHeader(subGroupIndex, match)
	end

	return match
end

---@param subGroupIndex integer
---@param match table
---@return string?
function CustomMatchGroupInput._getSubGroupHeader(subGroupIndex, match)
	local header = match['set' .. subGroupIndex .. 'header']

	return String.isNotEmpty(header) and header or nil
end

---@param match table
---@return table
function CustomMatchGroupInput._adjustData(match)
	--parse opponents + set base sumscores
	match = CustomMatchGroupInput._opponentInput(match)

	--main processing done here
	local subGroupIndex = 0
	for _, _, mapIndex in Table.iter.pairsByPrefix(match, 'map') do
		match, subGroupIndex = CustomMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	end

	match = CustomMatchGroupInput._matchWinnerProcessing(match)

	CustomMatchGroupInput._setPlacements(match)

	if CustomMatchGroupInput._hasTeamOpponent(match) then
		error('Team opponents are currently not yet supported on Magic wiki')
	end

	if Logic.isNumeric(match.winner) then
		match.finished = true
	end

	return match
end

---@param match table
---@return table
function CustomMatchGroupInput._matchWinnerProcessing(match)
	local bestof = tonumber(match.bestof) or Variables.varDefault('bestof', DEFAULT_BEST_OF)
	match.bestof = bestof
	Variables.varDefine('bestof', bestof)

	local scores = Array.map(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		local opponent = match['opponent' .. opponentIndex]
		if not opponent then
			return NO_SCORE
		end

		-- set the score either from manual input or sumscore
		opponent.score = Table.includes(ALLOWED_STATUSES, string.upper(opponent.score or ''))
			and string.upper(opponent.score)
			or tonumber(opponent.score) or tonumber(opponent.sumscore) or NO_SCORE

		return opponent.score
	end)

	walkoverProcessing.walkover(match, scores)

	if match.resulttype == DEFAULT_WIN_RESULTTYPE then
		walkoverProcessing.applyMatchWalkoverToOpponents(match)
		return match
	end

	if match.winner == 'draw' then
		match.winner = 0
	end

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isNotEmpty(opponent) then
			opponent.status = SCORE_STATUS
			if opponent.score > bestof / 2 then
				match.finished = Logic.emptyOr(match.finished, true)
				match.winner = tonumber(match.winner) or opponentIndex
			elseif match.winner == 0 or (opponent.score == bestof / 2 and match.opponent1.score == match.opponent2.score) then
				match.finished = Logic.emptyOr(match.finished, true)
				match.winner = 0
				match.resulttype = 'draw'
			end
		end
	end

	match.winner = tonumber(match.winner)

	CustomMatchGroupInput._checkFinished(match)

	if match.finished and not match.winner then
		CustomMatchGroupInput._determineWinnerIfMissing(match, scores)
	end

	return match
end

---@param match table
function CustomMatchGroupInput._checkFinished(match)
	if Logic.readBoolOrNil(match.finished) == false then
		match.finished = false
	elseif Logic.readBool(match.finished) or match.winner then
		match.finished = true
	end

	-- Match is automatically marked finished upon page edit after a
	-- certain amount of time (depending on whether the date is exact)
	if not match.finished and match.timestamp > DateExt.defaultTimestamp then
		local threshold = match.dateexact and 30800 or 86400
		if match.timestamp + threshold < NOW then
			match.finished = true
		end
	end
end

---@param match table
---@param scores number[]
function CustomMatchGroupInput._determineWinnerIfMissing(match, scores)
	local maxScore = math.max(unpack(scores) or 0)
	-- if we have a positive score and the match is finished we also have a winner
	if maxScore > 0 then
		if Array.all(scores, function(score) return score == maxScore end) then
			match.winner = 0
			return
		end

		for opponentIndex, score in pairs(scores) do
			if score == maxScore then
				match.winner = opponentIndex
				return
			end
		end
	end
end

---@param match table
function CustomMatchGroupInput._setPlacements(match)
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]

		if match.winner == opponentIndex or match.winner == 0 then
			opponent.placement = 1
		elseif match.winner then
			opponent.placement = 2
		end
	end
end

--[[

OpponentInput functions

]]--

---@param match table
---@return table
function CustomMatchGroupInput._opponentInput(match)
	local opponentIndex = 1
	local opponent = match['opponent' .. opponentIndex]

	while opponentIndex <= MAX_NUM_OPPONENTS and Logic.isNotEmpty(opponent) do
		opponent = Json.parseIfString(opponent) or Opponent.blank()

		-- Convert byes to literals
		if Opponent.isBye(opponent)
		then
			opponent = {type = Opponent.literal, name = BYE}
		end

		--process input
		if opponent.type == Opponent.team or opponent.type == Opponent.solo or
			opponent.type == Opponent.literal then

			opponent = CustomMatchGroupInput.processOpponent(opponent, match.timestamp)
		else
			error('Unsupported Opponent Type')
		end

		--set initial opponent sumscore
		opponent.sumscore = 0

		match['opponent' .. opponentIndex] = opponent

		opponentIndex = opponentIndex + 1
		opponent = match['opponent' .. opponentIndex]
	end

	return match
end

---@param record table
---@param timestamp integer
---@return table
function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	---@type number|string
	local teamTemplateDate = timestamp
	-- If date is default date, resolve using tournament dates instead
	-- default date indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not the default date
	if teamTemplateDate == DateExt.defaultTimestamp then
		teamTemplateDate = Variables.varDefaultMulti('tournament_enddate', 'tournament_startdate', NOW)
	end

	Opponent.resolve(opponent, teamTemplateDate, {syncPlayer=true})

	MatchGroupInput.mergeRecordWithOpponent(record, opponent)

	for _, player in pairs(record.players or {}) do
		player.name = player.name:gsub(' ', '_')
	end

	if record.name then
		record.name = record.name:gsub(' ', '_')
	end

	return record
end

--[[

MapInput functions

]]--

---@param match table
---@param mapIndex integer
---@param subGroupIndex integer
---@return table
---@return integer
function CustomMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	local map = Json.parseIfString(match['map' .. mapIndex])

	if Table.isEmpty(map) then
		match['map' .. mapIndex] = nil
		return match, subGroupIndex
	end

	-- Magic has no map names, use generic one instead
	map.map = 'Game ' .. mapIndex

	-- set initial extradata for maps
	map.extradata = {
		comment = map.comment,
	}

	-- determine score, resulttype, walkover and winner
	map = CustomMatchGroupInput._mapWinnerProcessing(map)

	-- get participants data for the map + get map mode
	map = CustomMatchGroupInput._processPlayerMapData(map, match)

	-- set sumscore to 0 if it isn't a number
	if Logic.isEmpty(match.opponent1.sumscore) then
		match.opponent1.sumscore = 0
	end
	if Logic.isEmpty(match.opponent2.sumscore) then
		match.opponent2.sumscore = 0
	end

	--adjust sumscore for winner opponent
	if (tonumber(map.winner) or 0) > 0 then
		match['opponent' .. map.winner].sumscore =
			match['opponent' .. map.winner].sumscore + 1
	end

	match['map' .. mapIndex] = map

	return match, subGroupIndex
end

---@param map table
---@return table
function CustomMatchGroupInput._mapWinnerProcessing(map)
	if map.winner == 'skip' then
		map.scores = {NO_SCORE, NO_SCORE}
		map.resulttype = 'np'

		return map
	end

	map.scores = {}
	local hasManualScores = false

	local scores = Array.map(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		local score = map['score' .. opponentIndex]
		map.scores[opponentIndex] = tonumber(score) or NO_SCORE

		if String.isNotEmpty(score) then
			hasManualScores = true
		end

		return Table.includes(ALLOWED_STATUSES, string.upper(score or ''))
			and score:upper()
			or map.scores[opponentIndex]
	end)

	if not hasManualScores then
		local winnerInput = tonumber(map.winner)
		if winnerInput == 1 then
			map.scores = {1, 0}
		elseif winnerInput == 2 then
			map.scores = {0, 1}
		end

		return map
	end

	walkoverProcessing.walkover(map, scores)

	return map
end

---@param map table
---@param match table
---@return table
function CustomMatchGroupInput._processPlayerMapData(map, match)
	local participants = {}

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]
		if Opponent.typeIsParty(opponent.type) then
			CustomMatchGroupInput._processDefaultPlayerMapData(
				opponent.match2players or {},
				opponentIndex,
				map,
				participants
			)
		elseif opponent.type == Opponent.team then
			error('Team opponents are currently not yet supported on magic wiki')
		end
	end

	map.mode = Opponent.toMode(match.opponent1.type, match.opponent2.type)

	map.participants = participants

	return map
end

---@param players table
---@param opponentIndex integer
---@param map table
---@param participants table<string, table>
function CustomMatchGroupInput._processDefaultPlayerMapData(players, opponentIndex, map, participants)
	for playerIndex = 1, #players do
		participants[opponentIndex .. '_' .. playerIndex] = {
			played = true,
		}
	end
end

---@param match table
---@return boolean
function CustomMatchGroupInput._hasTeamOpponent(match)
	return match.opponent1.type == Opponent.team or match.opponent2.type == Opponent.team
end

---@param obj table
---@param scores (integer|string)[]
function walkoverProcessing.walkover(obj, scores)
	local walkover = obj.walkover

	if Logic.isNumeric(walkover) then
		walkoverProcessing.numericWalkover(obj, walkover)
	elseif walkover then
		walkoverProcessing.nonNumericWalkover(obj, walkover)
	elseif #scores ~=2 then -- since we always have 2 opponents outside of ffa
		error('Unexpected number of opponents when calculating winner')
	elseif Array.all(scores, function(score)
			return Table.includes(ALLOWED_STATUSES, score) and score ~= DEFAULT_WIN_STATUS
		end) then

		walkoverProcessing.scoreDoubleWalkover(obj, scores)
	elseif Array.any(scores, function(score) return Table.includes(ALLOWED_STATUSES, score) end) then
		walkoverProcessing.scoreWalkover(obj, scores)
	end
end

---@param obj table
---@param walkover integer|string
function walkoverProcessing.numericWalkover(obj, walkover)
	local winner = tonumber(walkover)

	obj.winner = winner
	obj.finished = true
	obj.walkover = UNKNOWN_REASON_LOSS_STATUS
	obj.resulttype = DEFAULT_WIN_RESULTTYPE
end

---@param obj table
---@param walkover integer|string
function walkoverProcessing.nonNumericWalkover(obj, walkover)
	if not Table.includes(ALLOWED_STATUSES, string.upper(walkover)) then
		error('Invalid walkover "' .. walkover .. '"')
	elseif not Logic.isNumeric(obj.winner) then
		error('Walkover without winner specified')
	end

	obj.winner = tonumber(obj.winner)
	obj.finished = true
	obj.walkover = walkover:upper()
	obj.resulttype = DEFAULT_WIN_RESULTTYPE
end

---@param obj table
---@param scores string[]
function walkoverProcessing.scoreDoubleWalkover(obj, scores)
	obj.winner = -1
	obj.finished = true
	obj.walkover = scores[1]
	obj.resulttype = DEFAULT_WIN_RESULTTYPE
end

---@param obj table
---@param scores (string|number)[]
function walkoverProcessing.scoreWalkover(obj, scores)
	local winner, status

	for scoreIndex, score in pairs(scores) do
		score = string.upper(score)
		if score == DEFAULT_WIN_STATUS then
			winner = scoreIndex
		elseif Table.includes(ALLOWED_STATUSES, score) then
			status = score
		else
			status = UNKNOWN_REASON_LOSS_STATUS
		end
	end

	if not winner then
		error('Invalid score combination "{' .. scores[1] .. ', ' .. scores[2] .. '}"')
	end

	obj.winner = winner
	obj.finished = true
	obj.walkover = status
	obj.resulttype = DEFAULT_WIN_RESULTTYPE
end

---@param match table
function walkoverProcessing.applyMatchWalkoverToOpponents(match)
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local score = match['opponent' .. opponentIndex].score

		if Logic.isNumeric(score) or String.isEmpty(score) then
			match['opponent' .. opponentIndex].score = String.isNotEmpty(score) and score or NO_SCORE
			match['opponent' .. opponentIndex].status = match.walkover
		elseif score and Table.includes(ALLOWED_STATUSES, score:upper()) then
			match['opponent' .. opponentIndex].score = NO_SCORE
			match['opponent' .. opponentIndex].status = score
		else
			error('Invalid score "' .. score .. '"')
		end
	end

	-- neither match.opponent0 nor match['opponent-1'] does exist hence the if
	if match['opponent' .. match.winner] then
		match['opponent' .. match.winner].status = DEFAULT_WIN_STATUS
	end
end

return CustomMatchGroupInput

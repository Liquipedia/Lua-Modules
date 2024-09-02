---
-- @Liquipedia
-- wiki=easportsfc
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Flags = require('Module:Flags')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Ordinal = require('Module:Ordinal')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input/Util')
local Streams = Lua.import('Module:Links/Stream')

local OpponentLibrary = require('Module:OpponentLibraries')
local Opponent = OpponentLibrary.Opponent

local UNKNOWN_REASON_LOSS_STATUS = 'L'
local DEFAULT_WIN_STATUS = 'W'
local DEFAULT_WIN_RESULTTYPE = 'default'
local NO_SCORE = -1
local SCORE_STATUS = 'S'
local ALLOWED_STATUSES = {DEFAULT_WIN_STATUS, 'FF', 'DQ', UNKNOWN_REASON_LOSS_STATUS}
local MAX_NUM_OPPONENTS = 2
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])
local TBD = 'tbd'
local BYE = 'BYE'

local CustomMatchGroupInput = {}

CustomMatchGroupInput.walkoverProcessing = {}
local walkoverProcessing = CustomMatchGroupInput.walkoverProcessing

-- called from Module:MatchGroup
---@param match table
---@return table
function CustomMatchGroupInput.processMatch(match)
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))

	CustomMatchGroupInput._getExtraData(match)
	CustomMatchGroupInput._getTournamentVars(match)
	CustomMatchGroupInput._adjustData(match)
	CustomMatchGroupInput._getVodStuff(match)

	return match
end

---@param match table
function CustomMatchGroupInput._getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'solo'))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))

	MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
function CustomMatchGroupInput._getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod)
end

---@param match table
function CustomMatchGroupInput._getExtraData(match)
	match.extradata = {
		casters = MatchGroupInput.readCasters(match, {noSort = true}),
		hassubmatches = tostring(Logic.readBool(match.hasSubmatches)),
	}
end

---@param match table
function CustomMatchGroupInput._adjustData(match)
	CustomMatchGroupInput._opponentInput(match)

	for _, _, mapIndex in Table.iter.pairsByPrefix(match, 'map') do
		CustomMatchGroupInput._mapInput(match, mapIndex)
	end

	local scores = Array.map(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		local score = CustomMatchGroupInput._computeOpponentMatchScore(match, opponentIndex)
		match['opponent' .. opponentIndex].score = score
		if Logic.isNumeric(score) then
			match['opponent' .. opponentIndex].status = SCORE_STATUS
		end
		return score
	end)

	CustomMatchGroupInput._winnerProcessing(match, scores, true)

	CustomMatchGroupInput._setPlacements(match)
end

---@param obj table
---@param scores integer[]
---@param isMatch boolean?
function CustomMatchGroupInput._winnerProcessing(obj, scores, isMatch)
	walkoverProcessing.walkover(obj, scores)

	if isMatch and obj.resulttype == DEFAULT_WIN_RESULTTYPE then
		walkoverProcessing.applyMatchWalkoverToOpponents(obj)
		return
	end

	if obj.winner == 'draw' then
		obj.winner = 0
		obj.resulttype = 'draw'
		obj.finished = true
	end

	obj.finished = CustomMatchGroupInput._isFinished(obj)

	obj.winner = tonumber(obj.winner)

	if obj.finished and not obj.winner then
		obj.winner = CustomMatchGroupInput._determineWinnerIfMissing(scores)
	end
end

---@param match table
---@param opponentIndex integer
---@return number|string
function CustomMatchGroupInput._computeOpponentMatchScore(match, opponentIndex)
	if not match['opponent' .. opponentIndex] then
		return NO_SCORE
	end

	-- if valid manual input return that
	local score = match['opponent' .. opponentIndex].score
	if Logic.isNumeric(score) then
		return tonumber(score) --[[@as number]]
	elseif Table.includes(ALLOWED_STATUSES, (score or ''):upper()) then
		return score:upper()
	end

	if not match.map1 or not match.map1.winner then
		return NO_SCORE
	end

	local sumScore = 0

	-- if submatches count submatch/map wins
	if Logic.readBool(match.hasSubmatches) then
		for _, map in Table.iter.pairsByPrefix(match, 'map') do
			if map.winner == opponentIndex then
				sumScore = sumScore + 1
			end
		end

		return sumScore
	end

	-- if won in penalty shoot out return score of that shoot out
	for _, map in Table.iter.pairsByPrefix(match, 'map') do
		if Logic.readBool(map.penalty) then
			return map.scores[opponentIndex]
		end
	end

	-- sum up scores
	for _, map in Table.iter.pairsByPrefix(match, 'map') do
		local mapScore = map.scores[opponentIndex]
		if mapScore ~= NO_SCORE then
			sumScore = sumScore + mapScore
		end
	end

	return sumScore
end

---@param obj table
---@return boolean?
function CustomMatchGroupInput._isFinished(obj)
	if Logic.readBoolOrNil(obj.finished) == false then
		return false
	elseif Logic.readBool(obj.finished) or obj.winner then
		return true
	end

	-- Match is automatically marked finished upon page edit after a
	-- certain amount of time (depending on whether the date is exact)
	if obj.timestamp and obj.timestamp > DateExt.defaultTimestamp then
		local threshold = obj.dateexact and 30800 or 86400
		if obj.timestamp + threshold < NOW then
			return true
		end
	end
end

---@param scores integer[]
---@return integer?
function CustomMatchGroupInput._determineWinnerIfMissing(scores)
	local maxScore = math.max(unpack(scores or {0}))
	-- if we have a positive score and the match is finished we also have a winner
	if maxScore > 0 then
		if Array.all(scores, function(score) return score == maxScore end) then
			return 0
		end

		for opponentIndex, score in pairs(scores) do
			if score == maxScore then
				return opponentIndex
			end
		end
	end
end

---@param match any
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

---@param match table
function CustomMatchGroupInput._opponentInput(match)
	local opponentIndex = 1
	local opponent = match['opponent' .. opponentIndex]

	while opponentIndex <= MAX_NUM_OPPONENTS and Logic.isNotEmpty(opponent) do
		opponent = Json.parseIfString(opponent) or Opponent.blank()

		-- Convert byes to literals
		if Opponent.isBye(opponent) then
			opponent = {type = Opponent.literal, name = BYE}
		end

		--process input
		if opponent.type == Opponent.team or opponent.type == Opponent.solo or
			opponent.type == Opponent.literal then

			opponent = CustomMatchGroupInput.processOpponent(opponent, match.timestamp)
		else
			error('Unsupported Opponent Type: ' .. (opponent.type or ''))
		end

		match['opponent' .. opponentIndex] = opponent

		opponentIndex = opponentIndex + 1
		opponent = match['opponent' .. opponentIndex]
	end
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

	if record.type == Opponent.team then
		record.match2players = CustomMatchGroupInput._readTeamPlayers(record, record.players)
	end

	return record
end

---@param opponent table
---@param playerData string
---@return table
function CustomMatchGroupInput._readTeamPlayers(opponent, playerData)
	local players = CustomMatchGroupInput._getManuallyEnteredPlayers(playerData)

	if Table.isEmpty(players) then
		players = CustomMatchGroupInput._getPlayersFromVariables(opponent.name)
	end

	return players
end

---@param playerData string
---@return table
function CustomMatchGroupInput._getManuallyEnteredPlayers(playerData)
	local players = {}
	playerData = Json.parseIfString(playerData) or {}

	for prefix, displayName in Table.iter.pairsByPrefix(playerData, 'p') do
		local name = mw.ext.TeamLiquidIntegration.resolve_redirect(Logic.emptyOr(
			playerData[prefix .. 'link']
		) or displayName):gsub(' ', '_')

		table.insert(players, {
			name = name,
			displayname = displayName,
			flag = Flags.CountryName(playerData[prefix .. 'flag']),
		})
	end

	return players
end

---@param teamName string
---@return table[]
function CustomMatchGroupInput._getPlayersFromVariables(teamName)
	local teamNameWithSpaces = teamName:gsub('_', ' ')
	local players = {}

	local playerIndex = 1
	while true do
		local prefix = teamName .. '_p' .. playerIndex
		local prefixWithSpaces = teamNameWithSpaces .. '_p' .. playerIndex
		local playerName = Variables.varDefault(prefix, Variables.varDefault(prefixWithSpaces))
		if String.isEmpty(playerName) then
			break
		end
		---@cast playerName -nil
		table.insert(players, {
			name = playerName:gsub(' ', '_'),
			displayname = Variables.varDefault(
					prefix .. 'dn',
					Variables.varDefault(prefixWithSpaces .. 'dn', playerName:gsub('_', ' '))
			),
			flag = Flags.CountryName(Variables.varDefault(prefix .. 'flag', Variables.varDefault(prefixWithSpaces .. 'flag'))),
		})
		playerIndex = playerIndex + 1
	end

	return players
end

---@param match table
---@param mapIndex integer
function CustomMatchGroupInput._mapInput(match, mapIndex)
	local map = Json.parseIfString(match['map' .. mapIndex])

	if Table.isEmpty(map) then
		match['map' .. mapIndex] = nil
		return
	end

	if Logic.readBool(match.hasSubmatches) then
		-- generic map name (not displayed)
		map.map = 'Game ' .. mapIndex
	elseif Logic.readBool(map.penalty) then
		map.map = 'Penalties'
	else
		map.map = mapIndex .. Ordinal.suffix(mapIndex) .. ' Leg'
	end

	-- set initial extradata for maps
	map.extradata = {
		comment = map.comment,
		penaltyscores = CustomMatchGroupInput._submatchPenaltyScores(match, map),
	}

	-- determine score, resulttype, walkover and winner
	CustomMatchGroupInput._mapWinnerProcessing(map)

	-- get participants data for the map + get map mode
	CustomMatchGroupInput._processPlayerMapData(map, match)

	match['map' .. mapIndex] = map
end

---@param match table
---@param map table
---@return integer[]?
function CustomMatchGroupInput._submatchPenaltyScores(match, map)
	if not Logic.readBool(match.hasSubmatches) then
		return
	end

	local hasPenalties = false
	local scores = Array.map(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		local score = tonumber(map['penaltyScore' .. opponentIndex])
		hasPenalties = hasPenalties or (score ~= nil)
		return score or 0
	end)

	return hasPenalties and scores or nil
end

---@param map table
function CustomMatchGroupInput._mapWinnerProcessing(map)
	if map.winner == 'skip' then
		map.scores = {NO_SCORE, NO_SCORE}
		map.resulttype = 'np'

		return
	end

	map.scores = {}

	local scores = Array.map(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		local score = map['score' .. opponentIndex]
		map.scores[opponentIndex] = tonumber(score) or NO_SCORE

		return Table.includes(ALLOWED_STATUSES, string.upper(score or ''))
			and score:upper()
			or map.scores[opponentIndex]
	end)

	CustomMatchGroupInput._winnerProcessing(map, scores)
end

---@param map table
---@param match table
function CustomMatchGroupInput._processPlayerMapData(map, match)
	local participants = {}

	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		local opponent = match['opponent' .. opponentIndex]
		if opponent.type == Opponent.team and Logic.readBool(match.hasSubmatches) then
			CustomMatchGroupInput._processTeamPlayerMapData(
				opponent.match2players or {},
				opponentIndex,
				map,
				participants
			)
		else
			CustomMatchGroupInput._processDefaultPlayerMapData(
				opponent.match2players or {},
				opponentIndex,
				map,
				participants
			)
		end
	end

	map.mode = Opponent.toMode(match.opponent1.type, match.opponent2.type)

	map.participants = participants
end

---@param players table[]
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

---@param players table[]
---@param opponentIndex integer
---@param map table
---@param participants table<string, table>
function CustomMatchGroupInput._processTeamPlayerMapData(players, opponentIndex, map, participants)
	local prefix = 't' .. opponentIndex .. 'p'

	-- we need at least 1 player so if none ist set use TBD
	if String.isEmpty(map[prefix .. 1]) then
		map[prefix .. 1] = TBD
	end

	for playerKey, player in Table.iter.pairsByPrefix(map, prefix) do
		if player:lower() ~= TBD then
			-- allows fetching the link of the player from preset wiki vars
			player = mw.ext.TeamLiquidIntegration.resolve_redirect(
				map[playerKey .. 'link'] or Variables.varDefault(player .. '_page') or player
			)
		end

		local playerData = {
			played = true,
		}

		local match2playerIndex = CustomMatchGroupInput._fetchMatch2PlayerIndexOfPlayer(players, player)

		-- if we have the player not present in match2player add basic data here
		if not match2playerIndex then
			match2playerIndex = #players + 1
			playerData = Table.merge(playerData, {name = player:gsub(' ', '_'), displayname = map[playerKey] or player})
		end

		participants[opponentIndex .. '_' .. match2playerIndex] = playerData
	end
end

---@param players table[]
---@param player string
---@return integer?
function CustomMatchGroupInput._fetchMatch2PlayerIndexOfPlayer(players, player)
	local displayNameIndex
	local displayNameFoundTwice = false
	player = mw.ext.TeamLiquidIntegration.resolve_redirect(player)
	local playerWithUnderscores = player:gsub(' ', '_')

	for match2playerIndex, match2player in pairs(players) do
		if match2player and match2player.name == playerWithUnderscores then
			return match2playerIndex
		elseif not displayNameIndex and match2player and match2player.displayname == player then
			displayNameIndex = match2playerIndex
		elseif match2player and match2player.displayname == player then
			displayNameFoundTwice = true
		end
	end

	if not displayNameFoundTwice then
		return displayNameIndex
	end
end

---@param obj table
---@param scores string[]
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
---@param walkover string|integer
function walkoverProcessing.numericWalkover(obj, walkover)
	local winner = tonumber(walkover)

	obj.winner = winner
	obj.finished = true
	obj.walkover = UNKNOWN_REASON_LOSS_STATUS
	obj.resulttype = DEFAULT_WIN_RESULTTYPE
end

---@param obj table
---@param walkover string
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
---@param scores (integer|string)[]
function walkoverProcessing.scoreDoubleWalkover(obj, scores)
	obj.winner = -1
	obj.finished = true
	obj.walkover = scores[1]
	obj.resulttype = DEFAULT_WIN_RESULTTYPE
end

---@param obj table
---@param scores (integer|string)[]
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
			match['opponent' .. opponentIndex].score = tonumber(score) or NO_SCORE
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

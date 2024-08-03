---
-- @Liquipedia
-- wiki=clashroyale
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
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local CardNames = mw.loadData('Module:CardNames')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
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
local DEFAULT_BEST_OF = 99
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])
local ROYALE_API_PREFIX = 'https://royaleapi.com/'
local MAX_NUM_MAPS = 30

-- containers for process helper functions
local matchFunctions = {}
local walkoverProcessing = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@return table
function CustomMatchGroupInput.processMatch(match)
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = matchFunctions.getExtraData(match)
	match = CustomMatchGroupInput._getTournamentVars(match)
	match = CustomMatchGroupInput._adjustData(match)
	match = matchFunctions.getVodStuff(match)

	return match
end

---@param template string
---@return string|nil icon
---@return string|nil iconDark
function CustomMatchGroupInput.getIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	if raw then
		local icon = Logic.emptyOr(raw.image, raw.legacyimage)
		local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
		return icon, iconDark
	end
end

---@param obj table
---@param scores table
function walkoverProcessing.walkover(obj, scores)
	if #scores ~= 2 then -- since we always have 2 opponents
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
---@param scores table
function walkoverProcessing.scoreDoubleWalkover(obj, scores)
	obj.winner = -1
	obj.finished = true
	obj.walkover = scores[1]
	obj.resulttype = DEFAULT_WIN_RESULTTYPE
end

---@param obj table
---@param scores table
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

---@param match table
---@return boolean True
function CustomMatchGroupInput._hasTeamOpponent(match)
	return match.opponent1.type == Opponent.team or match.opponent2.type == Opponent.team
end

---@param match table
---@return table
function CustomMatchGroupInput._getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'solo'))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.nilIfEmpty(match.vod)

	match.links = {
		royaleapi = match.royaleapi and (ROYALE_API_PREFIX .. match.royaleapi) or nil,
	}

	return match
end

---@param match table
---@return table
function matchFunctions.getExtraData(match)
	match.extradata = {
		t1bans = CustomMatchGroupInput._readBans(match.t1bans),
		t2bans = CustomMatchGroupInput._readBans(match.t2bans),
		mvp = MatchGroupInput.readMvp(match),
	} --[[@as table]]

	for subGroupIndex = 1, MAX_NUM_MAPS do
		local prefix = 'subgroup' .. subGroupIndex

		match.extradata[prefix .. 'header'] = String.nilIfEmpty(match['subgroup' .. subGroupIndex .. 'header'])
		match.extradata[prefix .. 'iskoth'] = Logic.readBool(match[prefix .. 'iskoth']) or nil
		match.extradata[prefix .. 't1bans'] = CustomMatchGroupInput._readBans(match[prefix .. 't1bans'])
		match.extradata[prefix .. 't2bans'] = CustomMatchGroupInput._readBans(match[prefix .. 't2bans'])
	end

	return match
end

---@param bansInput string
---@return table
function CustomMatchGroupInput._readBans(bansInput)
	local bans = CustomMatchGroupInput._readCards(bansInput)

	return Logic.nilIfEmpty(bans)
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
		match = CustomMatchGroupInput._subMatchStructure(match)
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

	Array.forEach(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isEmpty(opponent) then return end
		opponent.status = SCORE_STATUS
		if opponent.score > bestof / 2 then
			match.finished = Logic.emptyOr(match.finished, true)
			match.winner = tonumber(match.winner) or opponentIndex
		elseif match.winner == 0 or (opponent.score == bestof / 2 and match.opponent1.score == match.opponent2.score) then
			match.finished = Logic.emptyOr(Logic.readBoolOrNil(match.finished), true)
			match.winner = 0
			match.resulttype = 'draw'
		end
	end)

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
---@param scores table
function CustomMatchGroupInput._determineWinnerIfMissing(match, scores)
	local maxScore = math.max(unpack(scores) or 0)
	-- if we have a positive score and the match is finished we also have a winner
	if maxScore <= 0 then return end

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

---@param match table
---@return table
function CustomMatchGroupInput._subMatchStructure(match)
	local subMatches = {}

	local currentSubGroup = 0
	for _, map in Table.iter.pairsByPrefix(match, 'map') do
		local subGroupIndex = tonumber(map.subgroup)
		if subGroupIndex then
			currentSubGroup = subGroupIndex
		else
			currentSubGroup = currentSubGroup + 1
			subGroupIndex = currentSubGroup
		end

		if not subMatches[subGroupIndex] then
			subMatches[subGroupIndex] = {scores = {0, 0}}
		end

		local winner = tonumber(map.winner)
		if winner and subMatches[subGroupIndex].scores[winner] then
			subMatches[subGroupIndex].scores[winner] = subMatches[subGroupIndex].scores[winner] + 1
		end
	end

	Array.forEach(subMatches, function(subMatch, subMatchIndex)
		-- get winner if the submatch is finished
		-- submatch is finished if the next submatch has a score or if the complete match is finished
		local nextSubMatch = subMatches[subMatchIndex + 1] or {scores = {0, 0}}

		if not Logic.readBool(match.finished) and (nextSubMatch.scores[1] + nextSubMatch.scores[2] <= 0) then
			return
		end
		if subMatch.scores[1] > subMatch.scores[2] then
			subMatch.winner = 1
		elseif subMatch.scores[2] > subMatch.scores[1] then
			subMatch.winner = 2
		end
	end)

	match.extradata.submatches = subMatches

	return match
end

---@param match table
---@return table
function CustomMatchGroupInput._opponentInput(match)
	Array.forEach(Array.range(1, MAX_NUM_OPPONENTS), FnUtil.curry(CustomMatchGroupInput.processOpponent, match))

	return match
end

---@param match table
---@param opponentIndex integer
function CustomMatchGroupInput.processOpponent(match, opponentIndex)
	local record = Json.parseIfString(match['opponent' .. opponentIndex])
	assert(Opponent.isType(record.type), 'Unsupported Opponent Type')

	local opponent = Opponent.readOpponentArgs(record) or Opponent.blank()

	-- Convert byes to literals
	if Opponent.isBye(opponent) then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	---@type number|string
	local teamTemplateDate = match.timestamp
	-- If date is default date, resolve using tournament dates instead
	-- default date indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not the default date
	if teamTemplateDate == DateExt.defaultTimestamp then
		teamTemplateDate = DateExt.getContextualDateOrNow()
	end

	Opponent.resolve(opponent, teamTemplateDate, {syncPlayer = true})

	MatchGroupInput.mergeRecordWithOpponent(record, opponent)

	--set initial opponent sumscore
	record.sumscore = 0

	record.name = Page.pageifyLink(record.name)

	if record.type == Opponent.team then
		record.icon, record.icondark = CustomMatchGroupInput.getIcon(opponent.template)
	end

	match['opponent' .. opponentIndex] = record

	if record.type == Opponent.team then
		MatchGroupInput.readPlayersOfTeam(match, opponentIndex, record.name, {
			resolveRedirect = true,
			applyUnderScores = true,
		})
	else
		Array.forEach(record.players or {}, function(player)
			player.name = Page.pageifyLink(player.name)
		end)
	end
end

---@param match table
---@param mapIndex integer
---@param subGroupIndex integer
---@return table, integer
function CustomMatchGroupInput._mapInput(match, mapIndex, subGroupIndex)
	local map = Json.parseIfString(match['map' .. mapIndex]) or {}

	if Table.isEmpty(map) then
		match['map' .. mapIndex] = nil
		return match, subGroupIndex
	end

	map = MatchGroupInput.getCommonTournamentVars(map, match)

	-- CR has no map names, use generic one instead
	map.map = 'Set ' .. mapIndex

	-- set initial extradata for maps
	map.extradata = {
		comment = map.comment,
		header = map.header,
	}

	-- determine score, resulttype, walkover and winner
	map = CustomMatchGroupInput._mapWinnerProcessing(map)

	-- get participants data for the map + get map mode
	map = CustomMatchGroupInput._processPlayerMapData(map, match)

	-- set sumscore to 0 if it isn't a number
	match.opponent1.sumscore = Logic.emptyOr(match.opponent1.sumscore, 0)
	match.opponent2.sumscore = Logic.emptyOr(match.opponent2.sumscore, 0)

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

		if String.isEmpty(score) then
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
			CustomMatchGroupInput._processTeamPlayerMapData(
				opponent.match2players or {},
				opponentIndex,
				map,
				participants
			)
		end
	end

	map.mode = Opponent.toMode(match.opponent1.type, match.opponent2.type)

	map.participants = participants

	return map
end

---@param players table
---@param opponentIndex integer
---@param map table
---@param participants table
function CustomMatchGroupInput._processDefaultPlayerMapData(players, opponentIndex, map, participants)
	Array.forEach(Array.range(1, #players), function(playerIndex)
		participants[opponentIndex .. '_' .. playerIndex] = {
			played = true,
			cards = CustomMatchGroupInput._readCards(map['t' .. opponentIndex .. 'p' .. playerIndex .. 'c']),
		}
	end)
end

---@param players table
---@param opponentIndex integer
---@param map table
---@param participants table
---@return integer
function CustomMatchGroupInput._processTeamPlayerMapData(players, opponentIndex, map, participants)
	local numberOfPlayersInMap = 0
	for prefix, player in Table.iter.pairsByPrefix(map, 't' .. opponentIndex .. 'p') do
		numberOfPlayersInMap = numberOfPlayersInMap + 1
		local link = mw.ext.TeamLiquidIntegration.resolve_redirect(
			map[prefix .. 'link'] or Variables.varDefault(player .. '_page') or player
		)

		local playerData = {
			played = true,
			cards = CustomMatchGroupInput._readCards(map[prefix .. 'c']),
		}

		local match2playerIndex = CustomMatchGroupInput._fetchMatch2PlayerIndexOfPlayer(players, link)

		if not match2playerIndex then
			table.insert(players, {
				--check the format in the existing players field please and adjust accordingly
				name = link:gsub(' ', '_'),
				displayname = player,
			})
			match2playerIndex = #players
		end

		participants[opponentIndex .. '_' .. match2playerIndex] =  playerData
	end

	return numberOfPlayersInMap
end

---@param players table
---@param player string
---@return integer|nil
function CustomMatchGroupInput._fetchMatch2PlayerIndexOfPlayer(players, player)
	local displayNameIndex
	local displayNameFoundTwice = false

	for match2playerIndex, match2player in pairs(players) do
		local playerWithUnderscores = player:gsub(' ', '_')
		if match2player and match2player.name == playerWithUnderscores then
			return match2playerIndex
		elseif not displayNameIndex and match2player and match2player.displayname == playerWithUnderscores then
			displayNameIndex = match2playerIndex
		elseif match2player and match2player.displayname == playerWithUnderscores then
			displayNameFoundTwice = true
		end
	end

	if not displayNameFoundTwice then
		return displayNameIndex
	end
end

---@param input string
---@return table
function CustomMatchGroupInput._readCards(input)
	local cleanCard = FnUtil.curry(MatchGroupInput.getCharacterName, CardNames)

	return Table.map(Json.parseIfString(input) or {}, function(key, card)
		return key, cleanCard(card)
	end)
end

return CustomMatchGroupInput

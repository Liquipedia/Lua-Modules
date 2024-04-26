---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Streams = require('Module:Links/Stream')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local Opponent = Lua.import('Module:Opponent')

local _ALLOWED_STATUSES = {'W', 'FF', 'DQ', 'L', 'D'}
local _FINISHED_INDICATORS = {'skip', 'np', 'cancelled', 'canceled'}
local _MAX_NUM_OPPONENTS = 8
local _MAX_NUM_MAPS = 9
local _DEFAULT_BESTOF = 3
local _NO_SCORE = -99

local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(match, options)
	-- Count number of maps, and automatically count score
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.getScoreFromMapWinners(match)

	-- process match
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)

	return map
end

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

	Opponent.resolve(opponent, teamTemplateDate)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processPlayer(player)
	return player
end

--
--
-- function to check for draws
function CustomMatchGroupInput.placementCheckDraw(tbl)
	local last
	for _, scoreInfo in pairs(tbl) do
		if scoreInfo.status ~= 'S' and scoreInfo.status ~= 'D' then
			return false
		end
		if last and last ~= scoreInfo.score then
			return false
		else
			last = scoreInfo.score
		end
	end

	return true
end

function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	-- Map or Match wasn't played, set not played
	if Table.includes(_FINISHED_INDICATORS, data.finished) or Table.includes(_FINISHED_INDICATORS, data.winner) then
		data.resulttype = 'np'
		data.finished = true
	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	elseif Logic.readBool(data.finished) then
		if CustomMatchGroupInput.placementCheckDraw(indexedScores) then
			data.winner = 0
			data.resulttype = 'draw'
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 'draw')
		elseif CustomMatchGroupInput.placementCheckSpecialStatus(indexedScores) then
			data.winner = CustomMatchGroupInput.getDefaultWinner(indexedScores)
			data.resulttype = 'default'
			if CustomMatchGroupInput.placementCheckFF(indexedScores) then
				data.walkover = 'ff'
			elseif CustomMatchGroupInput.placementCheckDQ(indexedScores) then
				data.walkover = 'dq'
			elseif CustomMatchGroupInput.placementCheckWL(indexedScores) then
				data.walkover = 'l'
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 'default')
		else
			local winner
			indexedScores, winner = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, nil, data.finished)
			data.winner = data.winner or winner
		end
	end

	--set it as finished if we have a winner
	if not Logic.isEmpty(data.winner) then
		data.finished = true
	end

	return data, indexedScores
end

function CustomMatchGroupInput.setPlacement(opponents, winner, specialType, finished)
	if specialType == 'draw' then
		for key, _ in pairs(opponents) do
			opponents[key].placement = 1
		end
	elseif specialType == 'default' then
		for key, _ in pairs(opponents) do
			if key == winner then
				opponents[key].placement = 1
			else
				opponents[key].placement = 2
			end
		end
	else
		local lastScore = _NO_SCORE
		local lastPlacement = _NO_SCORE
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
				lastScore = score or _NO_SCORE
			end
		end
	end

	return opponents, winner
end

function CustomMatchGroupInput.placementSortFunction(tbl, key1, key2)
	local value1 = tonumber(tbl[key1].score or _NO_SCORE) or _NO_SCORE
	local value2 = tonumber(tbl[key2].score or _NO_SCORE) or _NO_SCORE
	return value1 > value2
end

-- Check if any team has a none-standard status
function CustomMatchGroupInput.placementCheckSpecialStatus(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status ~= 'S' end)
end

-- function to check for forfeits
function CustomMatchGroupInput.placementCheckFF(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status == 'FF' end)
end

-- function to check for DQ's
function CustomMatchGroupInput.placementCheckDQ(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status == 'DQ' end)
end

-- function to check for W/L
function CustomMatchGroupInput.placementCheckWL(tbl)
	return Table.any(tbl, function (_, scoreinfo) return scoreinfo.status == 'L' end)
end

-- Get the winner when resulttype=default
function CustomMatchGroupInput.getDefaultWinner(tbl)
	for index, scoreInfo in pairs(tbl) do
		if scoreInfo.status == 'W' then
			return index
		end
	end
	return -1
end

--
-- match related functions
--
function matchFunctions.getBestOf(match)
	match.bestof = Logic.emptyOr(match.bestof, Variables.varDefault('bestof', _DEFAULT_BESTOF))
	Variables.varDefine('bestof', match.bestof)
	return match
end

-- Calculate the match scores based on the map results (counting map wins)
-- Only update a teams result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
function matchFunctions.getScoreFromMapWinners(match)
	local opponentNumber = 0
	for index = 1, _MAX_NUM_OPPONENTS do
		if String.isEmpty(match['opponent' .. index]) then
			break
		end
		opponentNumber = index
	end
	local newScores = {}
	local foundScores = false

	for i = 1, _MAX_NUM_MAPS do
		if match['map'..i] then
			local winner = tonumber(match['map'..i].winner)
			foundScores = true
			if winner and winner > 0 and winner <= opponentNumber then
				newScores[winner] = (newScores[winner] or 0) + 1
			end
		else
			break
		end
	end

	for index = 1, opponentNumber do
		if not match['opponent' .. index].score and foundScores then
			match['opponent' .. index].score = newScores[index] or 0
		end
	end

	return match
end

function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'team'))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_publishertier'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {}
	local links = match.links
	if match.owl then links.owl = 'https://web.archive.org/web/overwatchleague.com/en-us/match/' .. match.owl end
	if match.jcg then links.jcg = 'https://web.archive.org/web/ow.j-cg.com/compe/view/match/' .. match.jcg end
	if match.tespa then links.tespa = 'https://web.archive.org/web/compete.tespa.org/tournament/' .. match.tespa end
	if match.overgg then links.overgg = 'http://www.over.gg/' .. match.overgg end
	if match.pf then links.pf = 'http://www.plusforward.net/overwatch/post/' .. match.pf end
	if match.wl then links.wl = 'https://www.winstonslab.com/matches/match.php?id=' .. match.wl end
	if match.faceit then links.faceit = 'https://www.faceit.com/en/ow2/room/' .. match.faceit end
	if match.stats then links.stats = match.stats end

	return match
end

function matchFunctions.getExtraData(match)
	match.extradata = {
		mvp = MatchGroupInput.readMvp(match),
	}
	return match
end

function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, _MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

			-- apply status
			if Logic.isNumeric(opponent.score) then
				opponent.status = 'S'
				isScoreSet = true
			elseif Table.includes(_ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
			end
			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == Opponent.team and not Logic.isEmpty(opponent.name) then
				match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name)
			end
		end
	end

	-- see if match should actually be finished if bestof limit was reached
	if isScoreSet and not Logic.readBool(match.finished) then
		local firstTo = math.ceil(match.bestof/2)
		for _, item in pairs(opponents) do
			if (tonumber(item.score or 0) or 0) >= firstTo then
				match.finished = true
				break
			end
		end
	end

	-- check if match should actually be finished due to a non score status
	if not Logic.readBool(match.finished) then
		for _, opponent in pairs(opponents) do
			if String.isNotEmpty(opponent.status) and opponent.status ~= 'S' then
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
	if not Logic.isEmpty(match.winner) or Logic.readBool(match.finished) then
		match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)
	end

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end
	return match
end

--
-- map related functions
--

-- Parse extradata information
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
	}
	return map
end

-- Calculate Score and Winner of the map
function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, _MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex] or map['t' .. scoreIndex .. 'score']
		local obj = {}
		if not Logic.isEmpty(score) then
			if Logic.isNumeric(score) then
				obj.status = 'S'
				obj.score = score
			elseif Table.includes(_ALLOWED_STATUSES, score) then
				obj.status = score
				obj.score = -1
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

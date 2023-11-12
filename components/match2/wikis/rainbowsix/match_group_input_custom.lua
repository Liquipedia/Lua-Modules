---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input', {requireDevIfEnabled = true})
local Opponent = Lua.import('Module:Opponent', {requireDevIfEnabled = true})

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L', 'D' }
local ALLOWED_VETOES = { 'decider', 'pick', 'ban', 'defaultban' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_MAPS = 9
local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.

local EPOCH_TIME_EXTENDED = '1970-01-01T00:00:00+00:00'
local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}
local opponentFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
function CustomMatchGroupInput.processMatch(match, options)
	-- Count number of maps, check for empty maps to remove, and automatically count score
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.removeUnsetMaps(match)
	match = matchFunctions.getScoreFromMapWinners(match)

	-- process match
	Table.mergeInto(match, matchFunctions.readDate(match))
	match = matchFunctions.getOpponents(match)
	match = CustomMatchGroupInput.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)
	map = CustomMatchGroupInput.getTournamentVars(map)

	return map
end

function CustomMatchGroupInput.processOpponent(record, timestamp)
	local opponent = Opponent.readOpponentArgs(record)
		or Opponent.blank()

	-- Convert byes to literals
	if opponent.type == Opponent.team and opponent.template:lower() == 'bye' then
		opponent = {type = Opponent.literal, name = 'BYE'}
	end

	local teamTemplateDate = timestamp
	-- If date is epoch, resolve using tournament dates instead
	-- Epoch indicates that the match is missing a date
	-- In order to get correct child team template, we will use an approximately date and not 1970-01-01
	if teamTemplateDate == DateExt.epochZero then
		teamTemplateDate = Variables.varDefaultMulti(
			'tournament_enddate',
			'tournament_startdate',
			NOW
		)
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
function CustomMatchGroupInput.placementCheckDraw(table)
	local last
	for _, scoreInfo in pairs(table) do
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

-- Set the field 'placement' for the two participants in the opponenets list.
-- Set the placementWinner field to the winner, and placementLoser to the other team
-- Special cases:
-- If Winner = 0, that means draw, and placementLoser isn't used. Both teams will get placementWinner
-- If Winner = -1, that mean no team won, and placementWinner isn't used. Both teams will get placementLoser
function CustomMatchGroupInput.setPlacement(opponents, winner, placementWinner, placementLoser)
	if opponents and #opponents == 2 then
		local loserIdx
		local winnerIdx
		if winner == 1 then
			winnerIdx = 1
			loserIdx = 2
		elseif winner == 2 then
			winnerIdx = 2
			loserIdx = 1
		elseif winner == 0 then
			-- Draw; idx of winner/loser doesn't matter
			-- since loser and winner gets the same placement
			placementLoser = placementWinner
			winnerIdx = 1
			loserIdx = 2
		elseif winner == -1 then
			-- No Winner (both loses). For example if both teams DQ.
			-- idx's doesn't matter
			placementWinner = placementLoser
			winnerIdx = 1
			loserIdx = 2
		else
			error('setPlacement: Unexpected winner')
			return opponents
		end
		opponents[winnerIdx].placement = placementWinner
		opponents[loserIdx].placement = placementLoser
	end
	return opponents
end

--- Fetch information about the tournament
function CustomMatchGroupInput.getTournamentVars(data)
	data.mode = Logic.emptyOr(data.mode, Variables.varDefault('tournament_mode', 'team'))
	return MatchGroupInput.getCommonTournamentVars(data)
end

function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	-- Map or Match wasn't played, set not played
	if data.finished == 'skip' or data.finished == 'np' or data.finished == 'cancelled' or data.finished == 'canceled' then
		data.resulttype = 'np'
	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	elseif Logic.readBool(data.finished) then
		if CustomMatchGroupInput.placementCheckDraw(indexedScores) then
			data.winner = 0
			data.resulttype = 'draw'
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 1)
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
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
		else
			--R6 only has exactly 2 opponents, neither more or less
			if #indexedScores ~= 2 then
				error('Unexpected number of opponents when calculating winner')
			end
			if tonumber(indexedScores[1].score) > tonumber(indexedScores[2].score) then
				data.winner = 1
			else
				data.winner = 2
			end
			indexedScores = CustomMatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
		end
	end
	return data, indexedScores
end


-- Check if any team has a none-standard status
function CustomMatchGroupInput.placementCheckSpecialStatus(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status ~= 'S' end)
end

-- function to check for forfeits
function CustomMatchGroupInput.placementCheckFF(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'FF' end)
end

-- function to check for DQ's
function CustomMatchGroupInput.placementCheckDQ(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'DQ' end)
end

-- function to check for W/L
function CustomMatchGroupInput.placementCheckWL(table)
	return Table.any(table, function (_, scoreinfo) return scoreinfo.status == 'L' end)
end

-- Get the winner when resulttype=default
function CustomMatchGroupInput.getDefaultWinner(table)
	for index, scoreInfo in pairs(table) do
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
	match.bestof = #Array.filter(Array.range(1, MAX_NUM_MAPS), function(idx) return match['map'.. idx] end)
	return match
end

-- Template:Map sets a default map name so we can count the number of maps.
-- These maps however shouldn't be stored in lpdb, nor displayed
-- The discardMap function will check if a map should be removed
-- Remove all maps that should be removed.
function matchFunctions.removeUnsetMaps(match)
	for i = 1, MAX_NUM_MAPS do
		if match['map'..i] then
			if mapFunctions.discardMap(match['map'..i]) then
				match['map'..i] = nil
			end
		else
			break
		end
	end
	return match
end

-- Calculate the match scores based on the map results.
-- If it's a Best of 1, we'll take the exact score of that map
-- If it's not a Best of 1, we should count the map wins
-- Only update a teams result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
function matchFunctions.getScoreFromMapWinners(match)
	-- For best of 1, display the results of the single map
	local opponent1 = match.opponent1
	local opponent2 = match.opponent2
	local newScores = {}
	local foundScores = false
	if match.bestof == 1 then
		if match.map1 then
			newScores = match.map1.scores
			foundScores = true
		end
	else -- For best of >1, disply the map wins
		for i = 1, MAX_NUM_MAPS do
			if match['map'..i] then
				local winner = tonumber(match['map'..i].winner)
				foundScores = true
				-- Only two opponents in R6
				if winner and winner > 0 and winner <= 2 then
					newScores[winner] = (newScores[winner] or 0) + 1
				end
			else
				break
			end
		end
	end
	if not opponent1.score and foundScores then
		opponent1.score = newScores[1] or 0
	end
	if not opponent2.score and foundScores then
		opponent2.score = newScores[2] or 0
	end
	match.opponent1 = opponent1
	match.opponent2 = opponent2
	return match
end

function matchFunctions.readDate(matchArgs)
	if matchArgs.date then
		return MatchGroupInput.readDate(matchArgs.date)
	else
		return {
			date = EPOCH_TIME_EXTENDED,
			dateexact = false,
			timestamp = DateExt.epochZero,
		}
	end
end

function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {
		preview = match.preview,
		stats = match.stats,
		siegegg = match.siegegg and 'https://siege.gg/matches/' .. match.siegegg or nil,
		opl = match.opl and 'https://www.opleague.eu/match/' .. match.opl or nil,
		esl = match.esl and 'https://play.eslgaming.com/match/' .. match.esl or nil,
		faceit = match.faceit and 'https://www.faceit.com/en/rainbow_6/room/' .. match.faceit or nil,
		lpl = match.lpl and 'https://old.letsplay.live/match/' .. match.lpl or nil,
		r6esports = match.r6esports
			and 'https://www.ubisoft.com/en-us/esports/rainbow-six/siege/match/' .. match.r6esports or nil,
		challengermode = match.challengermode and 'https://www.challengermode.com/games/' .. match.challengermode or nil,
		ebattle = match.ebattle and 'https://www.ebattle.gg/turnier/match/' .. match.ebattle or nil,
	}

	return match
end

function matchFunctions.getExtraData(match)
	match.extradata = {
		mapveto = matchFunctions.getMapVeto(match),
		mvp = MatchGroupInput.readMvp(match),
		casters = MatchGroupInput.readCasters(match, {noSort = true}),
	}
	return match
end

-- Parse the mapVeto input
function matchFunctions.getMapVeto(match)
	if not match.mapveto then return nil end

	match.mapveto = Json.parseIfString(match.mapveto)

	local vetoTypes = mw.text.split(match.mapveto.types or '', ',')
	local deciders = mw.text.split(match.mapveto.decider or '', ',')
	local vetoStart = match.mapveto.firstpick or ''
	local deciderIndex = 1

	local data = {}
	for index, vetoType in ipairs(vetoTypes) do
		vetoType = mw.text.trim(vetoType):lower()
		if not Table.includes(ALLOWED_VETOES, vetoType) then
			return nil -- Any invalid input will not store (ie hide) all vetoes.
		end
		if vetoType == 'decider' then
			table.insert(data, {type = vetoType, decider = deciders[deciderIndex]})
			deciderIndex = deciderIndex + 1
		else
			table.insert(data, {type = vetoType, team1 = match.mapveto['t1map'..index], team2 = match.mapveto['t2map'..index]})
		end
	end
	if data[1] then
		data[1].vetostart = vetoStart
	end
	return data
end

function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

			-- Retrieve icon for team
			if opponent.type == Opponent.team then
				opponent.icon, opponent.icondark = opponentFunctions.getIcon(opponent.template)
			end

			-- apply status
			if TypeUtil.isNumeric(opponent.score) then
				opponent.status = 'S'
				isScoreSet = true
			elseif Table.includes(ALLOWED_STATUSES, opponent.score) then
				opponent.status = opponent.score
				opponent.score = -1
			end
			opponents[opponentIndex] = opponent

			-- get players from vars for teams
			if opponent.type == 'team' and not Logic.isEmpty(opponent.name) then
				match = MatchGroupInput.readPlayersOfTeam(match, opponentIndex, opponent.name)
			end
		end
	end

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.timestamp ~= DateExt.epochZero then
		local threshold = match.dateexact and 30800 or 86400
		if match.timestamp + threshold < NOW then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	match, opponents = CustomMatchGroupInput.getResultTypeAndWinner(match, opponents)

	-- Update all opponents with new values
	for opponentIndex, opponent in pairs(opponents) do
		match['opponent' .. opponentIndex] = opponent
	end
	return match
end

--
-- map related functions
--

-- Check if a map should be discarded due to being redundant
-- DUMMY_MAP_NAME needs the match the default value in Template:Map
function mapFunctions.discardMap(map)
	return map.map == DUMMY_MAP_NAME
end

-- Parse extradata information, particularally info about halfs and operator bans
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
		t1firstside = {rt = map.t1firstside, ot = map.t1firstsideot},
		t1halfs = {atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = {atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
		t1bans = {map.t1ban1, map.t1ban2},
		t2bans = {map.t2ban1, map.t2ban2},
		pick = map.pick
	}
	return map
end

-- Calculate Score and Winner of the map
-- Use the half information if available
function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex]
		if map['t'.. scoreIndex ..'atk'] or map['t'.. scoreIndex ..'def'] then
			score = (tonumber(map['t'.. scoreIndex ..'atk']) or 0)
					+ (tonumber(map['t'.. scoreIndex ..'def']) or 0)
					+ (tonumber(map['t'.. scoreIndex ..'otatk']) or 0)
					+ (tonumber(map['t'.. scoreIndex ..'otdef']) or 0)
		end
		local obj = {}
		if not Logic.isEmpty(score) then
			if TypeUtil.isNumeric(score) then
				obj.status = 'S'
				obj.score = score
			elseif Table.includes(ALLOWED_STATUSES, score) then
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

--
-- opponent related functions
--
function opponentFunctions.getIcon(template)
	local raw = mw.ext.TeamTemplate.raw(template)
	if raw then
		local icon = Logic.emptyOr(raw.image, raw.legacyimage)
		local iconDark = Logic.emptyOr(raw.imagedark, raw.legacyimagedark)
		return icon, iconDark
	end
end

return CustomMatchGroupInput

---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterNames = require('Module:CharacterNames')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')
local Opponent = Lua.import('Module:Opponent')

local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L', 'D' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_MAPS = 9
local MAX_NUM_BANS = 2
local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.

local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	-- Count number of maps, check for empty maps to remove, and automatically count score
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.removeUnsetMaps(match)
	match = matchFunctions.getScoreFromMapWinners(match)

	-- process match
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = matchFunctions.getOpponents(match)
	match = CustomMatchGroupInput.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)
	match = matchFunctions.getExtraData(match)

	return match
end

-- called from Module:Match/Subobjects
---@param map table
---@return table
function CustomMatchGroupInput.processMap(map)
	map = mapFunctions.getExtraData(map)
	map = mapFunctions.getScoresAndWinner(map)

	return map
end

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

	Opponent.resolve(opponent, teamTemplateDate)
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

--- Fetch information about the tournament
---@param data table
---@return table
function CustomMatchGroupInput.getTournamentVars(data)
	data.mode = Logic.emptyOr(data.mode, Variables.varDefault('tournament_mode', 'team'))
	return MatchGroupInput.getCommonTournamentVars(data)
end

---@param data table
---@param indexedScores table[]
---@return table
---@return table[]
function CustomMatchGroupInput.getResultTypeAndWinner(data, indexedScores)
	-- Map or Match wasn't played, set not played
	if data.finished == 'skip' or data.finished == 'np' or data.finished == 'cancelled' or data.finished == 'canceled' then
		data.resulttype = 'np'
	-- Map or Match is marked as finished.
	-- Calculate and set winner, resulttype, placements and walkover (if applicable for the outcome)
	elseif Logic.readBool(data.finished) then
		if MatchGroupInput.isDraw(indexedScores) then
			data.winner = 0
			data.resulttype = 'draw'
			indexedScores = MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 1)
		elseif MatchGroupInput.hasSpecialStatus(indexedScores) then
			data.winner = MatchGroupInput.getDefaultWinner(indexedScores)
			data.resulttype = 'default'
			if MatchGroupInput.hasForfeit(indexedScores) then
				data.walkover = 'ff'
			elseif MatchGroupInput.hasDisqualified(indexedScores) then
				data.walkover = 'dq'
			elseif MatchGroupInput.hasDefaultWinLoss(indexedScores) then
				data.walkover = 'l'
			end
			indexedScores = MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
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
			indexedScores = MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
		end
	end
	return data, indexedScores
end

--
-- match related functions
--

---@param match table
---@return table
function matchFunctions.getBestOf(match)
	match.bestof = #Array.filter(Array.range(1, MAX_NUM_MAPS), function(idx) return match['map'.. idx] end)
	return match
end

-- Template:Map sets a default map name so we can count the number of maps.
-- These maps however shouldn't be stored in lpdb, nor displayed
-- The discardMap function will check if a map should be removed
-- Remove all maps that should be removed.
---@param match table
---@return table
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
---@param match table
---@return table
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

---@param match table
---@return table
function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = {
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

---@param match table
---@return table
function matchFunctions.getExtraData(match)
	match.extradata = {
		mapveto = MatchGroupInput.getMapVeto(match),
		mvp = MatchGroupInput.readMvp(match),
		casters = MatchGroupInput.readCasters(match, {noSort = true}),
	}
	return match
end

---@param match table
---@return table
function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	for opponentIndex = 1, MAX_NUM_OPPONENTS do
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if not Logic.isEmpty(opponent) then
			CustomMatchGroupInput.processOpponent(opponent, match.timestamp)

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
	if isScoreSet and not Logic.readBool(match.finished) and match.timestamp ~= DateExt.defaultTimestamp then
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
---@param map table
---@return boolean
function mapFunctions.discardMap(map)
	return map.map == DUMMY_MAP_NAME
end

-- Parse extradata information, particularally info about halfs and operator bans
---@param map table
---@return table
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
		t1firstside = {rt = map.t1firstside, ot = map.t1firstsideot},
		t1halfs = {atk = map.t1atk, def = map.t1def, otatk = map.t1otatk, otdef = map.t1otdef},
		t2halfs = {atk = map.t2atk, def = map.t2def, otatk = map.t2otatk, otdef = map.t2otdef},
		t1bans = {},
		t2bans = {},
		pick = map.pick
	}

	local getCharacterName = FnUtil.curry(MatchGroupInput.getCharacterName, CharacterNames)
	Array.forEach(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		map.extradata['t' .. opponentIndex .. 'bans'] = Array.map(Array.range(1, MAX_NUM_BANS), function (banIndex)
			local ban = map['t' .. opponentIndex .. 'ban' .. banIndex]
			return getCharacterName(ban) or ''
		end)
	end)
	return map
end

-- Calculate Score and Winner of the map
-- Use the half information if available
---@param map table
---@return table
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

return CustomMatchGroupInput

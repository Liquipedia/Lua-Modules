---
-- @Liquipedia
-- wiki=teamfortress
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Opponent = require('Module:Opponent')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')
local Variables = require('Module:Variables')
local DateExt = require('Module:Date/Ext')
local Streams = require('Module:Links/Stream')

local MatchGroupInput = Lua.import('Module:MatchGroup/Input')

local NP_STATUSES = {'skip', 'np', 'canceled', 'cancelled'}
local ALLOWED_STATUSES = { 'W', 'FF', 'DQ', 'L', 'D' }
local MAX_NUM_OPPONENTS = 2
local MAX_NUM_MAPS = 20

local NOW = os.time(os.date('!*t') --[[@as osdateparam]])

local LINK_PREFIXES = {
	rgl = 'https://rgl.gg/Public/Match.aspx?m=',
	ozf = 'https://warzone.ozfortress.com/matches/',
	etf2l = 'http://etf2l.org/matches/',
	tftv = 'http://tf.gg/',
	esl = 'https://play.eslgaming.com/match/',
	esea = 'https://play.esea.net/match/',
}

-- containers for process helper functions
local matchFunctions = {}
local mapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@return table
function CustomMatchGroupInput.processMatch(match)
	-- Count number of maps, check for empty maps to remove, and automatically count score
	match = matchFunctions.getBestOf(match)
	match = matchFunctions.getScoreFromMapWinners(match)

	-- process match
	Table.mergeInto(match, MatchGroupInput.readDate(match.date))
	match = matchFunctions.getOpponents(match)
	match = matchFunctions.getTournamentVars(match)
	match = matchFunctions.getVodStuff(match)

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
	local teamTemplateDate = DateExt.nilIfDefaultTimestamp(timestamp) or
		Variables.varDefaultMulti('tournament_enddate', 'tournament_startdate', NOW)

	Opponent.resolve(opponent, teamTemplateDate, {syncPlayer = true})
	MatchGroupInput.mergeRecordWithOpponent(record, opponent)
end

-- called from Module:Match/Subobjects
---@param player table
---@return table
function CustomMatchGroupInput.processPlayer(player)
	return player
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
			MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 1)
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
			local winner
			indexedScores, winner = MatchGroupInput.setPlacement(indexedScores, data.winner, 1, 2)
			data.winner = data.winner or winner
		end
	end

	--set it as finished if we have a winner
	if Logic.isNotEmpty(data.winner) then
		data.finished = true
	end

	return data, indexedScores
end

---@param opponents table[]
---@param winner integer?
---@param specialType string?
---@param finished boolean|string?
---@return table[]
---@return integer?
function MatchGroupInput.setPlacement(opponents, winner, specialType, finished)
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
		local temporaryScore
		local temporaryPlace = -99
		local counter = 0
		for scoreIndex, opp in Table.iter.spairs(opponents, CustomMatchGroupInput.placementSortFunction) do
			local score = tonumber(opp.score) or ''
			counter = counter + 1
			if counter == 1 and Logic.isEmpty(winner) then
				if finished then
					winner = scoreIndex
				end
			end
			if temporaryScore == score then
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement) or temporaryPlace
			else
				opponents[scoreIndex].placement = tonumber(opponents[scoreIndex].placement) or counter
				temporaryPlace = counter
				temporaryScore = score
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
	local value1 = tonumber(tbl[key1].score) or -99
	local value2 = tonumber(tbl[key2].score) or -99
	return value1 > value2
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

-- Calculate the match scores based on the map results (counting map wins)
-- Only update a teams result if it's
-- 1) Not manually added
-- 2) At least one map has a winner
---@param match table
---@return table
function matchFunctions.getScoreFromMapWinners(match)
	local opponentNumber = 0
	for index = 1, MAX_NUM_OPPONENTS do
		if String.isEmpty(match['opponent' .. index]) then
			break
		end
		opponentNumber = index
	end
	local newScores = {}
	local foundScores = false

	for _, map, i in Table.iter.pairsByPrefix(match, 'map') do
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

	Array.forEach(Array.range(1, opponentNumber), function(index)
		if not match['opponent' .. index].score and foundScores then
			match['opponent' .. index].score = newScores[index] or 0
		end
	end)

	return match
end

---@param match table
---@return table
function matchFunctions.getTournamentVars(match)
	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', '6v6'))
	return MatchGroupInput.getCommonTournamentVars(match)
end

---@param match table
---@return table
function matchFunctions.getVodStuff(match)
	match.stream = Streams.processStreams(match)
	match.vod = Logic.emptyOr(match.vod, Variables.varDefault('vod'))

	match.links = Table.map(LINK_PREFIXES, function(prefix, link)
		return prefix, match[prefix] and (link .. match[prefix]) or nil
	end)

	return match
end

---@param match table
---@return table
function matchFunctions.getOpponents(match)
	-- read opponents and ignore empty ones
	local opponents = {}
	local isScoreSet = false
	Array.forEach(Array.range(1, MAX_NUM_OPPONENTS), function(opponentIndex)
		-- read opponent
		local opponent = match['opponent' .. opponentIndex]
		if Logic.isEmpty(opponent) then return end
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
	end)

	-- see if match should actually be finished if bestof limit was reached
	match.finished = Logic.readBool(match.finished)
		or isScoreSet and (
			Array.any(opponents, function(opponent) return (tonumber(opponent.score) or 0) > match.bestof/2 end)
			or Array.all(opponents, function(opponent) return (tonumber(opponent.score) or 0) == match.bestof/2 end)
		)

	-- see if match should actually be finished if score is set
	if isScoreSet and not Logic.readBool(match.finished) and match.timestamp ~= DateExt.defaultTimestamp then
		local threshold = match.dateexact and 30800 or 86400
		if match.timestamp + threshold < NOW then
			match.finished = true
		end
	end

	-- apply placements and winner if finshed
	if not String.isEmpty(match.winner) or Logic.readBool(match.finished) then
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
---@param map table
---@return table
function mapFunctions.getExtraData(map)
	map.extradata = {
		comment = map.comment,
		header = map.header,
		logstf = Logic.isNotEmpty(map.logstf) and ('https://logs.tf/' .. map.logstf) or nil,
		logstfgold = Logic.isNotEmpty(map.logstfgold) and ('https://logs.tf/' .. map.logstfgold) or nil,
	}

	return map
end

-- Calculate Score and Winner of the map
---@param map table
---@return table
function mapFunctions.getScoresAndWinner(map)
	map.scores = {}
	local indexedScores = {}
	for scoreIndex = 1, MAX_NUM_OPPONENTS do
		-- read scores
		local score = map['score' .. scoreIndex] or map['t' .. scoreIndex .. 'score']
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

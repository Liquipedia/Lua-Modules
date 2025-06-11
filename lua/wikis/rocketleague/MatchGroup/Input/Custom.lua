---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent')

local CustomMatchGroupInput = {}
local MatchFunctions = {}
local MapFunctions = {}

local EARNINGS_LIMIT_FOR_FEATURED = 10000
local CURRENT_YEAR = os.date('%Y')
MatchFunctions.DEFAULT_MODE = '3v3'
MatchFunctions.DATE_FALLBACKS = {'tournament_enddate'}
MatchFunctions.getBestOf = function (bestOfInput, maps) return tonumber(bestOfInput) end

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param opponent MGIParsedOpponent
---@param opponentIndex integer
function MatchFunctions.adjustOpponent(opponent, opponentIndex)
	opponent.extradata = CustomMatchGroupInput.getOpponentExtradata(opponent)
	if opponent.extradata.additionalScores then
		opponent.score = CustomMatchGroupInput._getSetWins(opponent)
	end
end

---@param match table
---@param opponents table[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		if map.map == nil then
			break
		end
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		local dateToUse = map.date or match.date
		Table.mergeInto(map, MatchGroupInputUtil.readDate(dateToUse))

		map.extradata = MapFunctions.getExtraData(map)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		map.opponents = Array.map(opponents, function(_, opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			})
			return {score = score, status = status}
		end)

		map.scores = Array.map(map.opponents, Operator.property('score'))

		if Logic.readBoolOrNil(finishedInput) == nil and Logic.isNotEmpty(map.scores) then
			map.finished = true
		end

		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, map.opponents)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

---@param opponent table
---@return table
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
---@param opponents table[]
---@return string?
function MatchFunctions.getHeadToHeadLink(match, opponents)
	if not Logic.readBool(Logic.emptyOr(match.showh2h, Variables.varDefault('showh2h'))) or
		opponents[1].type ~= Opponent.team or
		opponents[2].type ~= Opponent.team then

		return nil
	end

	local team1, team2 = mw.uri.encode(opponents[1].name), mw.uri.encode(opponents[2].name)
	return tostring(mw.uri.fullUrl('Special:RunQuery/Head2head'))
		.. '?RunQuery=Run&pfRunQueryFormName=Head2head&Headtohead%5Bteam1%5D='
		.. team1 .. '&Headtohead%5Bteam2%5D=' .. team2
end

---@param match table
---@param games table[]
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		isfeatured = MatchFunctions.isFeatured(opponents, tonumber(match.liquipediatier)),
		hasopponent1 = MatchFunctions._checkForNonEmptyOpponent(opponents[1]),
		hasopponent2 = MatchFunctions._checkForNonEmptyOpponent(opponents[2]),
		liquipediatiertype2 = Variables.varDefault('tournament_tiertype2'),
	}
end

---@param opponent table
---@return boolean
function MatchFunctions._checkForNonEmptyOpponent(opponent)
	if Opponent.typeIsParty(opponent.type) then
		local playerIsTbd = function (player)
			return String.isEmpty(player.displayname) or player.displayname:upper() == 'TBD'
		end
		return not Array.all(opponent.match2players, playerIsTbd)
	end
	-- Literal and Teams can use the default function, player's can not because of match2player vs player list names
	return not Opponent.isTbd(opponent)
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
		query = 'earningsbyyear'
	})[1]

	if not data then
		return 0
	end

	return data.earningsbyyear[tonumber(CURRENT_YEAR)] or 0
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
		header = map.header,
		--the following is used to store 'mapXtYgoals' from LegacyMatchLists
		t1goals = map.t1goals,
		t2goals = map.t2goals,
		timeout = Table.isNotEmpty(timeouts) and timeouts or nil,
	}
end

return CustomMatchGroupInput

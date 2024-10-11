---
-- @Liquipedia
-- wiki=counterstrike
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--
local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local EarningsOf = require('Module:Earnings of')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')
local Streams = require('Module:Links/Stream')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local DUMMY_MAP_NAME = 'null' -- Is set in Template:Map when |map= is empty.

local FEATURED_TIERS = {1, 2}
local MIN_EARNINGS_FOR_FEATURED = 200000

local OPPONENT_CONFIG = {
	maxNumPlayers = 5,
	resolveRedirect = true,
	applyUnderScores = true
}

-- containers for process helper functions
local MatchFunctions = {}
local MapFunctions = {}

local CustomMatchGroupInput = {}

-- called from Module:MatchGroup
---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	local finishedInput = match.finished --[[@as string?]]
	local winnerInput = match.winner --[[@as string?]]

	Table.mergeInto(match, MatchGroupInputUtil.readDate(match.date))

	local opponents = Array.mapIndexes(function(opponentIndex)
		return MatchGroupInputUtil.readOpponent(match, opponentIndex, OPPONENT_CONFIG)
	end)
	local games = MatchFunctions.extractMaps(match, #opponents)
	match.bestof = MatchGroupInputUtil.getBestOf(nil, games)
	games = MatchFunctions.removeUnsetMaps(games)

	local autoScoreFunction = MatchGroupInputUtil.canUseAutoScore(match, games)
		and MatchFunctions.calculateMatchScore(games)
		or nil
	Array.forEach(opponents, function(opponent, opponentIndex)
		opponent.score, opponent.status = MatchGroupInputUtil.computeOpponentScore({
			walkover = match.walkover,
			winner = match.winner,
			opponentIndex = opponentIndex,
			score = opponent.score,
		}, autoScoreFunction)
	end)

	match.finished = MatchGroupInputUtil.matchIsFinished(match, opponents)

	if match.finished then
		match.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
		match.winner = MatchGroupInputUtil.getWinner(match.status, winnerInput, opponents)
		Array.forEach(opponents, function(opponent, opponentIndex)
			opponent.placement = MatchGroupInputUtil.placementFromWinner(match.status, match.winner, opponentIndex)
		end)
	end

	match.mode = Logic.emptyOr(match.mode, Variables.varDefault('tournament_mode', 'team'))
	match.publishertier = Logic.emptyOr(match.publishertier, Variables.varDefault('tournament_valve_tier'))
	match.status = Logic.emptyOr(match.status, Variables.varDefault('tournament_status'))
	Table.mergeInto(match, MatchGroupInputUtil.getTournamentContext(match))

	match.stream = Streams.processStreams(match)
	match.links = MatchFunctions.getLinks(match, games)

	match.games = games
	match.opponents = opponents

	match.extradata = MatchFunctions.getExtraData(match, opponents)

	return match
end

--
-- match related functions
--

---@param match table
---@param opponentCount integer
---@return table[]
function MatchFunctions.extractMaps(match, opponentCount)
	local maps = {}
	for key, map in Table.iter.pairsByPrefix(match, 'map', {requireIndex = true}) do
		local finishedInput = map.finished --[[@as string?]]
		local winnerInput = map.winner --[[@as string?]]

		map.extradata = MapFunctions.getExtraData(map)
		map.finished = MatchGroupInputUtil.mapIsFinished(map)

		local opponentInfo = Array.map(Array.range(1, opponentCount), function(opponentIndex)
			local score, status = MatchGroupInputUtil.computeOpponentScore({
				walkover = map.walkover,
				winner = map.winner,
				opponentIndex = opponentIndex,
				score = map['score' .. opponentIndex],
			}, MapFunctions.calculateMapScore(map))
			return {score = score, status = status}
		end)

		map.scores = Array.map(opponentInfo, Operator.property('score'))
		if map.finished then
			map.status = MatchGroupInputUtil.getMatchStatus(winnerInput, finishedInput)
			map.winner = MatchGroupInputUtil.getWinner(map.status, winnerInput, opponentInfo)
		end

		table.insert(maps, map)
		match[key] = nil
	end

	return maps
end

--
-- match related functions
--

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return function(opponentIndex)
		return MatchGroupInputUtil.computeMatchScoreFromMapWinners(maps, opponentIndex)
	end
end

-- Template:Map sets a default map name so we can count the number of maps.
-- These maps however shouldn't be stored
-- The keepMap function will check if a map should be kept
---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, MapFunctions.keepMap)
end

---@param match table
---@param maps table[]
---@return table
function MatchFunctions.getLinks(match, maps)
	local platforms = mw.loadData('Module:MatchExternalLinks')
	table.insert(platforms, {name = 'vod2', isMapStats = true})

	return Table.map(platforms, function (key, platform)
		if Logic.isEmpty(platform) then
			return key, nil
		end

		local makeLink = function(name)
			local linkPrefix = platform.prefixLink or ''
			local linkSuffix = platform.suffixLink or ''
			return linkPrefix .. name .. linkSuffix
		end

		local linksOfPlatform = {}
		local name = platform.name

		if match[name] then
			table.insert(linksOfPlatform, {makeLink(match[name]), 0})
		end

		if platform.isMapStats then
			Array.forEach(maps, function(map, mapIndex)
				if not map[name] then
					return
				end
				table.insert(linksOfPlatform, {makeLink(map[name]), mapIndex})
			end)
		elseif platform.max then
			for i = 2, platform.max, 1 do
				if match[name .. i] then
					table.insert(linksOfPlatform, {makeLink(match[name .. i]), i})
				end
			end
		end

		if Logic.isEmpty(linksOfPlatform) then
			return name, nil
		end
		return name, linksOfPlatform
	end)
end

---@param match table
---@return string?
function MatchFunctions.getMatchStatus(match)
	if match.status == 'np' then
		return Logic.emptyOr(match.status, Variables.varDefault('tournament_status'))
	end
end

---@param name string?
---@param year string|osdate
---@return number
function MatchFunctions.getEarnings(name, year)
	if Logic.isEmpty(name) then
		return 0
	end

	return tonumber(EarningsOf._team(name, {sdate = (year-1) .. '-01-01', edate = year .. '-12-31'})) --[[@as number]]
end

---@param match table
---@param opponents table[]
---@return boolean
function MatchFunctions.isFeatured(match, opponents)
	if Table.includes(FEATURED_TIERS, tonumber(match.liquipediatier)) then
		return true
	end
	if Logic.isNotEmpty(match.publishertier) then
		return true
	end

	if match.timestamp == DateExt.defaultTimestamp then
		return false
	end

	local year = os.date('%Y')

	if
		opponents[1].type == Opponent.team and
		MatchFunctions.getEarnings(opponents[1].name, year) >= MIN_EARNINGS_FOR_FEATURED
	or
		opponents[2].type == Opponent.team and
		MatchFunctions.getEarnings(opponents[2].name, year) >= MIN_EARNINGS_FOR_FEATURED
	then
		return true
	end

	return false
end

---@param match table
---@param opponents table[]
---@return table
function MatchFunctions.getExtraData(match, opponents)
	return {
		mapveto = MatchGroupInputUtil.getMapVeto(match),
		status = MatchFunctions.getMatchStatus(match),
		overturned = Logic.isNotEmpty(match.overturned),
		featured = MatchFunctions.isFeatured(match, opponents),
		hidden = Logic.readBool(Variables.varDefault('match_hidden'))
	}
end

--
-- map related functions
--

-- Check if a map should be discarded due to being redundant
-- DUMMY_MAP_NAME needs the match the default value in Template:Map
---@param map table
---@return boolean
function MapFunctions.keepMap(map)
	return map.map ~= DUMMY_MAP_NAME
end

-- Parse extradata information
---@param map table
---@return table
function MapFunctions.getExtraData(map)
	local extradata = {
		comment = map.comment,
	}

	Table.mergeInto(extradata, MapFunctions._getHalfScores(map))

	return extradata
end

---@param map table
---@return table
function MapFunctions._getHalfScores(map)
	local t1sides = {}
	local t2sides = {}
	local t1halfs = {}
	local t2halfs = {}

	local prefix = ''
	local overtimes = 0

	local function getOppositeSide(side)
		return side == 'ct' and 't' or 'ct'
	end

	while true do
		local t1Side = map[prefix .. 't1firstside']
		if Logic.isEmpty(t1Side) or (t1Side ~= 'ct' and t1Side ~= 't') then
			break
		end
		local t2Side = getOppositeSide(t1Side)

		-- Iterate over two Halfs (In regular time a half is 15 rounds, after that sides switch)
		for _ = 1, 2, 1 do
			if(map[prefix .. 't1' .. t1Side] and map[prefix .. 't2' .. t2Side]) then
				table.insert(t1sides, t1Side)
				table.insert(t2sides, t2Side)
				table.insert(t1halfs, tonumber(map[prefix .. 't1' .. t1Side]) or 0)
				table.insert(t2halfs, tonumber(map[prefix .. 't2' .. t2Side]) or 0)
				-- second half (sides switch)
				t1Side, t2Side = t2Side, t1Side
			end
		end

		overtimes = overtimes + 1
		prefix = 'o' .. overtimes
	end

	return {
		t1sides = t1sides,
		t2sides = t2sides,
		t1halfs = t1halfs,
		t2halfs = t2halfs,
	}
end

---@param map table
---@return fun(opponentIndex: integer): integer?
function MapFunctions.calculateMapScore(map)
	local halfs = MapFunctions._getHalfScores(map)
	return function(opponentIndex)
		return Array.reduce(halfs['t' .. opponentIndex .. 'halfs'], Operator.add)
	end
end

return CustomMatchGroupInput

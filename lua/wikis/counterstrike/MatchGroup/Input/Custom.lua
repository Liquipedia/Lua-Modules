---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local EarningsOf = Lua.import('Module:Earnings of')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local HighlightConditions = Lua.import('Module:HighlightConditions')
local Opponent = Lua.import('Module:Opponent/Custom')
local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')

local FEATURED_TIERS = {1, 2}
local MIN_EARNINGS_FOR_FEATURED = 200000

-- containers for process helper functions
local CustomMatchGroupInput = {}

---@class CounterstrikeMatchParser: MatchParserInterface
---@field MapParser CounterstrikeNormalMapParser|CounterstrikeMatchPageMapParser?
local MatchFunctions = {
	DEFAULT_MODE = 'team',
	getBestOf = MatchGroupInputUtil.getBestOf,
	OPPONENT_CONFIG = {
		maxNumPlayers = 5,
		resolveRedirect = true,
		applyUnderScores = true,
	},
}

---@class CounterstrikeFfaMatchParser: FfaMatchParserInterface
local FfaMatchFunctions = {
	DEFAULT_MODE = 'team',
	OPPONENT_CONFIG = {
		maxNumPlayers = 5,
		resolveRedirect = true,
		applyUnderScores = true,
	},
}

---@class CounterstrikeFfaMapParser: FfaMapParserInterface
local FfaMapFunctions = {}

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	options = options or {}
	local finishedInput = Logic.nilIfEmpty(match.finished) or Variables.varDefault('tournament_status')
	match.finished = finishedInput

	if not options.isMatchPage then
		-- See if this match has a standalone match (match page), if so use the data from there
		local standaloneMatchId = MatchGroupInputUtil.getStandaloneId(match.bracketid, match.matchid)
		local standaloneMatch = standaloneMatchId
			and MatchGroupInputUtil.fetchStandaloneMatch(standaloneMatchId) or nil
		if standaloneMatch then
			return MatchGroupInputUtil.mergeStandaloneIntoMatch(match, standaloneMatch)
		end
	end

	MatchFunctions.MapParser = options.isMatchPage
		and Lua.import('Module:MatchGroup/Input/Custom/MatchPage')
		or Lua.import('Module:MatchGroup/Input/Custom/Normal')

	local processedMatch = MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions, FfaMatchFunctions)
	processedMatch.extradata.status = match.status == MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED and finishedInput or nil

	if options.isMatchPage then
		MatchFunctions.populateOpponentStats(processedMatch)
	end

	return processedMatch
end

---Aggregates each player's per-map stats into a single overall-series stat line, stashed onto player.extradata.overallStats for
---Module:MatchPage's "Overall Statistics" tab. Only nuselo maps with data
---contribute, a manually entered map has no per-player breakdown to fold in.
---@param match {opponents: MGIParsedOpponent[], games: table[]}
---@return table
function MatchFunctions.populateOpponentStats(match)
	Array.forEach(match.opponents, function(opponent, opponentIdx)
		Array.forEach(opponent.match2players or {}, function(player, playerIndex)
			player.extradata = player.extradata or {}
			player.extradata.overallStats = MatchFunctions.calculateOverallStatsForPlayer(match.games, opponentIdx, playerIndex)
		end)
	end)
	return match
end

---@param maps table[]
---@param opponentIndex integer
---@param playerIndex integer
---@return table
function MatchFunctions.calculateOverallStatsForPlayer(maps, opponentIndex, playerIndex)
	local playedMaps = Array.filter(maps, function(map)
		return map.status ~= MatchGroupInputUtil.MATCH_STATUS.NOT_PLAYED
	end)

	local playersWithData = Array.filter(Array.map(playedMaps, function(map)
		local opponent = map.opponents[opponentIndex]
		return opponent and opponent.players and opponent.players[playerIndex]
	end), Logic.isNotEmpty)

	if Logic.isEmpty(playersWithData) then
		return {}
	end

	local function sumOf(key)
		return Array.reduce(Array.map(playersWithData, function(player) return player[key] or 0 end), Operator.add, 0)
	end

	-- Simple mean across maps that have this player's data, not rounds-weighted
	-- Needs a change at either the API level of module in future
	local function averageOf(key)
		local values = Array.filter(Array.map(playersWithData, Operator.property(key)), Logic.isNotEmpty)
		if Logic.isEmpty(values) then
			return nil
		end
		return Array.reduce(values, Operator.add, 0) / #values
	end

	local firstEntry = playersWithData[1]

	return {
		player = firstEntry.player,
		displayName = firstEntry.displayName,
		kills = sumOf('kills'),
		deaths = sumOf('deaths'),
		assists = sumOf('assists'),
		adr = averageOf('adr'),
		hs = averageOf('hs'),
		firstKills = sumOf('firstKills'),
		firstDeaths = sumOf('firstDeaths'),
		-- Add some more eventually, side kills?
		kast = averageOf('kast'),
		awpKills = sumOf('awpKills'),
		tradeKills = sumOf('tradeKills'),
		tradeDeaths = sumOf('tradeDeaths'),
	}
end

-- "Normal" match

---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MatchFunctions.MapParser)
end

---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function MatchFunctions.calculateMatchScore(maps)
	return FnUtil.curry(MatchGroupInputUtil.computeMatchScoreFromMapWinners, maps)
end

---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil
	end)
end

---@param match table
---@param maps table[]
---@return table
function MatchFunctions.getLinks(match, maps)
	local platforms = Lua.import('Module:MatchExternalLinks', {loadData = true})
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
---@param opponents MGIParsedOpponent[]
---@return boolean
function MatchFunctions.isFeatured(match, opponents)
	if Table.includes(FEATURED_TIERS, tonumber(match.liquipediatier)) then
		return true
	end
	if HighlightConditions.tournament(match) then
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
---@param games table[]
---@param opponents MGIParsedOpponent[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		mapveto = MatchGroupInputUtil.getMapVeto(match),
		overturned = Logic.isNotEmpty(match.overturned),
		featured = MatchFunctions.isFeatured(match, opponents),
		hidden = Logic.readBool(Variables.varDefault('match_hidden'))
	}
end

--- FFA Match

---@param match table
---@param opponents MGIParsedOpponent[]
---@param scoreSettings table
---@return table[]
function FfaMatchFunctions.extractMaps(match, opponents, scoreSettings)
	return MatchGroupInputUtil.standardProcessFfaMaps(match, opponents, scoreSettings, FfaMapFunctions)
end

---@param opponents MGIParsedOpponent[]
---@param maps table[]
---@return fun(opponentIndex: integer): integer?
function FfaMatchFunctions.calculateMatchScore(opponents, maps)
	return function(opponentIndex)
		return Array.reduce(Array.map(maps, function(map)
			return map.opponents[opponentIndex].score or 0
		end), Operator.add, 0) + (opponents[opponentIndex].extradata.startingpoints or 0)
	end
end

return CustomMatchGroupInput

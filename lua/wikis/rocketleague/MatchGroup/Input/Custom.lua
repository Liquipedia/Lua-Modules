---
-- @Liquipedia
-- page=Module:MatchGroup/Input/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local MatchGroupInputUtil = Lua.import('Module:MatchGroup/Input/Util')
local Opponent = Lua.import('Module:Opponent/Custom')

local CustomMatchGroupInput = {}

---@class RocketLeagueMatchParser: MatchParserInterface
local MatchFunctions = {
	DEFAULT_MODE = '3v3',
	DATE_FALLBACKS = {'tournament_enddate'},
}

---@class RocketLeagueMapParser: MapParserInterface
local MapFunctions = {}

local EARNINGS_LIMIT_FOR_FEATURED = 10000
local CURRENT_YEAR = DateExt.getYearOf()

---@param match table
---@param options table?
---@return table
function CustomMatchGroupInput.processMatch(match, options)
	return MatchGroupInputUtil.standardProcessMatch(match, MatchFunctions)
end

---@param opponent MGIParsedOpponent
---@param opponentIndex integer
function MatchFunctions.adjustOpponent(opponent, opponentIndex)
	Table.mergeInto(opponent.extradata, CustomMatchGroupInput.getOpponentExtradata(opponent))
	if opponent.extradata.additionalScores then
		opponent.score = CustomMatchGroupInput._getSetWins(opponent)
	end
end

---@param match table
---@param opponents MGIParsedOpponent[]
---@return table[]
function MatchFunctions.extractMaps(match, opponents)
	return MatchGroupInputUtil.standardProcessMaps(match, opponents, MapFunctions)
end

---@param games table[]
---@return table[]
function MatchFunctions.removeUnsetMaps(games)
	return Array.filter(games, function(map)
		return map.map ~= nil
	end)
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

---@param opponent MGIParsedOpponent
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
---@param opponents MGIParsedOpponent[]
---@return string?
function MatchFunctions.getHeadToHeadLink(match, opponents)
	if not Logic.readBool(Logic.emptyOr(match.showh2h, Variables.varDefault('showh2h'))) or
		opponents[1].type ~= Opponent.team or
		opponents[2].type ~= Opponent.team then

		return nil
	end

	return tostring(mw.uri.fullUrl(
		'Special:RunQuery/Head2head',
		{
			RunQuery = 'Run',
			pfRunQueryFormName = 'Head2head',
			['Headtohead[team1]'] = opponents[1].name,
			['Headtohead[team2]'] = opponents[2].name,
		}
	))
end

---@param match table
---@param games table[]
---@param opponents MGIParsedOpponent[]
---@return table
function MatchFunctions.getExtraData(match, games, opponents)
	return {
		isfeatured = MatchFunctions.isFeatured(opponents, tonumber(match.liquipediatier)),
		hasopponent1 = not Opponent.isTbd(Opponent.fromMatchParsedOpponent(opponents[1])),
		hasopponent2 = not Opponent.isTbd(Opponent.fromMatchParsedOpponent(opponents[2])),
		liquipediatiertype2 = Variables.varDefault('tournament_tiertype2'),
	}
end

---@param opponents MGIParsedOpponent[]
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

---@param bestOfInput string|integer?
---@param maps table[]
---@return integer?
function MatchFunctions.getBestOf(bestOfInput, maps)
	return tonumber(bestOfInput)
end

--
-- map related functions
--

---@param map table
---@param opponents MGIParsedOpponent[]
---@param finishedInput string?
---@param winnerInput string?
---@return boolean
function MapFunctions.mapIsFinished(map, opponents, finishedInput, winnerInput)
	if MatchGroupInputUtil.mapIsFinished(map) then
		return true
	end
	return Logic.readBoolOrNil(finishedInput) == nil and Array.any(
		map.opponents, function (mapOpponent) return mapOpponent.score ~= nil end
	)
end

---@param match table
---@param map table
---@param opponents MGIParsedOpponent[]
---@return table
function MapFunctions.getExtraData(match, map, opponents)
	local timeouts = Array.extractValues(Table.mapValues(mw.text.split(map.timeout or '', ','), tonumber))

	return {
		ot = map.ot,
		otlength = map.otlength,
		header = map.header,
		--the following is used to store 'mapXtYgoals' from LegacyMatchLists
		t1goals = map.t1goals,
		t2goals = map.t2goals,
		timeout = Logic.nilIfEmpty(timeouts),
	}
end

return CustomMatchGroupInput

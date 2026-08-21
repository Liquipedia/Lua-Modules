---
-- @Liquipedia
-- page=Module:MatchGroup/Util/Match
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Date = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local FnUtil = Lua.import('Module:FnUtil')
local Info = Lua.import('Module:Info', {loadData = true})
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local BracketUtil = Lua.import('Module:MatchGroup/Util/Bracket')

local NOW = os.time()

local nilIfEmpty = String.nilIfEmpty

--[[
The match model: reading match records into matches, opponents, games and players, and the match ids that address them.

Reading a match record does mean interpreting the bracket data it carries,
which is why this imports Module:MatchGroup/Util/Bracket.
]]
local MatchUtil = {}

---Parse extradata as a JSON string if read from page variables. Otherwise create a copy if fetched from lpdb.
---The returned extradata table can then be mutated without altering the source.
---@param recordExtradata table|string?
---@return table
local function parseOrCopyExtradata(recordExtradata)
	return type(recordExtradata) == 'string' and Json.parse(recordExtradata)
		or type(recordExtradata) == 'table' and Table.copy(recordExtradata)
		or {}
end

---Converts a match record to a structurally typed table with the appropriate data types for field values.
---The match record is either a match created in the store bracket codepath (WikiSpecific.processMatch),
---or a record fetched from LPDB (MatchUtil.fetchMatchRecords).
---The returned match struct is used in various display components (Bracket, MatchSummary, etc)
---
---This is the implementation used on wikis by default. Wikis may specify a different conversion by setting
---WikiSpecific.matchFromRecord. Refer to the starcraft2 wiki as an example.
---@param record match2
---@return MatchGroupUtilMatch
function MatchUtil.matchFromRecord(record)
	local extradata = parseOrCopyExtradata(record.extradata)
	local opponents = Array.map(record.match2opponents, FnUtil.curry(MatchUtil.opponentFromRecord, record))
	local games = Array.map(record.match2games, function(game) return MatchUtil.gameFromRecord(game, #opponents) end)
	local bracketData = BracketUtil.bracketDataFromRecord(Json.parseIfString(record.match2bracketdata))
	if bracketData.type == 'bracket' then
		bracketData.lowerEdges = bracketData.lowerEdges
			or BracketUtil.autoAssignLowerEdges(#bracketData.lowerMatchIds, #opponents)
	end

	local walkover = nilIfEmpty(record.walkover)

	local match = {
		bestof = tonumber(record.bestof) or 0,
		bracketData = bracketData,
		comment = nilIfEmpty(Table.extract(extradata, 'comment')),
		extradata = extradata,
		date = record.date,
		dateIsExact = Logic.readBool(record.dateexact),
		finished = Logic.readBool(record.finished),
		game = record.game,
		games = games,
		icon = nilIfEmpty(record.icon),
		iconDark = nilIfEmpty(record.icondark),
		links = Json.parseIfString(record.links) or {},
		matchId = record.match2id,
		liquipediatier = record.liquipediatier,
		liquipediatiertype = record.liquipediatiertype,
		mode = record.mode,
		opponents = opponents,
		pageName = record.pagename,
		parent = record.parent,
		patch = record.patch,
		publisherTier = nilIfEmpty(record.publishertier),
		resultType = nilIfEmpty(record.resulttype),
		section = nilIfEmpty(record.section),
		series = nilIfEmpty(record.series),
		shortname = nilIfEmpty(record.shortname),
		status = nilIfEmpty(record.status),
		stream = Json.parseIfString(record.stream) or {},
		tickername = record.tickername,
		timestamp = tonumber(Table.extract(extradata, 'timestamp')),
		timezoneId = Table.extract(extradata, 'timezoneid'),
		tournament = record.tournament,
		type = nilIfEmpty(record.type) or 'literal',
		vod = nilIfEmpty(record.vod),
		walkover = walkover and walkover:lower() or nil,
		winner = tonumber(record.winner),
	}

	match.phase = MatchUtil.computeMatchPhase(match)

	return match
end

---@param matchRecord match2
---@param record match2opponent
---@param opponentIndex integer
---@return standardOpponent
function MatchUtil.opponentFromRecord(matchRecord, record, opponentIndex)
	local extradata = parseOrCopyExtradata(record.extradata)
	local score = record.score
	local status = record.status
	local bestof = tonumber(matchRecord.bestof)
	local game1 = (matchRecord.match2games or {})[1]
	local hasOnlyScores = Array.all(matchRecord.match2opponents, function(opponent)
			return opponent.status == 'S' end)
	local scoreDisplay = nil
	if bestof == 1 and Info.config.match2.gameScoresIfBo1 and game1 and hasOnlyScores then
		local mapOpponent = (game1.opponents or {})[opponentIndex] or {}
		scoreDisplay = tonumber(mapOpponent.score)
		status = mapOpponent.status
	end

	return {
		advanceBg = nilIfEmpty(Table.extract(extradata, 'bg')),
		advances = Logic.readBoolOrNil(Table.extract(extradata, 'advances')),
		extradata = extradata,
		icon = nilIfEmpty(record.icon),
		name = nilIfEmpty(record.name),
		placement = tonumber(record.placement),
		players = Array.map(record.match2players, MatchUtil.playerFromRecord),
		score = tonumber(score),
		scoreDisplay = scoreDisplay,
		status = status,
		template = nilIfEmpty(record.template),
		type = nilIfEmpty(record.type) or 'literal',
	}
end

-- TODO: standardOpponent overlaps Module:Opponent without being convertible to it, and this is the
-- only constructor in the match model that does not read a record. Worth reconciling the two
-- opponent shapes, at which point this may not need to exist.
---@param args table
---@return standardOpponent
function MatchUtil.createOpponent(args)
	return {
		extradata = args.extradata or {},
		icon = args.icon,
		name = args.name,
		placement = args.placement,
		players = args.players or {},
		score = args.score,
		status = args.status,
		template = args.template,
		type = args.type or 'literal',
	}
end

---@param record table
---@return standardPlayer
function MatchUtil.playerFromRecord(record)
	local extradata = parseOrCopyExtradata(record.extradata)
	local faction = Faction.read(extradata.faction)
	return {
		displayName = record.displayname,
		extradata = extradata,
		flag = nilIfEmpty(record.flag),
		pageName = record.name,
		team = Table.extract(extradata, 'playerteam'),
		faction = faction or Faction.defaultFaction,
		pageIsResolved = Logic.isNotEmpty(faction),
	}
end

---@param record match2game
---@param opponentCount integer?
---@return MatchGroupUtilGame
function MatchUtil.gameFromRecord(record, opponentCount)
	local extradata = parseOrCopyExtradata(record.extradata)

	return {
		comment = nilIfEmpty(Table.extract(extradata, 'comment')),
		date = record.date,
		dateIsExact = nilIfEmpty(Table.extract(extradata, 'dateexact')),
		extradata = extradata,
		game = record.game,
		header = nilIfEmpty(Table.extract(extradata, 'header')),
		length = record.length,
		map = nilIfEmpty(record.map),
		mapDisplayName = nilIfEmpty(Table.extract(extradata, 'displayname')),
		mode = nilIfEmpty(record.mode),
		opponents = record.opponents,
		patch = record.patch,
		resultType = nilIfEmpty(record.resulttype),
		status = nilIfEmpty(record.status),
		scores = Json.parseIfString(record.scores) or {},
		subgroup = tonumber(record.subgroup),
		timestamp = tonumber(Table.extract(extradata, 'timestamp')),
		timezoneId = Table.extract(extradata, 'timezoneid'),
		type = nilIfEmpty(record.type),
		vod = nilIfEmpty(record.vod),
		walkover = nilIfEmpty(record.walkover) and record.walkover:lower() or nil,
		winner = tonumber(record.winner),
	}
end

---Group games on the subgroup field to form submatches
---@param match MatchGroupUtilMatch
---@return MatchGroupUtilSubgroup[]
function MatchUtil.groupBySubgroup(match)
	local previousSubgroup = nil
	---@type MatchGroupUtilGame[]?
	local currentGames = nil
	---@type MatchGroupUtilGame[][]
	local submatchGames = {}
	Array.forEach(match.games, function (game)
		if previousSubgroup == nil or previousSubgroup ~= game.subgroup then
			currentGames = {}
			Array.appendWith(submatchGames, currentGames)
			previousSubgroup = game.subgroup
		end
		---@cast currentGames -nil
		Array.appendWith(currentGames, game)
	end)
	return Array.map(submatchGames, function (games, groupIndex)
		---@type MatchGroupUtilSubgroup
		return {
			games = games,
			subgroup = groupIndex,
			header = Table.extract(match.extradata or {}, 'subgroup' .. groupIndex .. 'header'),
		}
	end)
end


---Determines the phase of a match based on its properties.
---@param match MatchGroupUtilMatch|MatchGroupUtilGame|PartialMatchGameRecord
---@return 'finished'|'ongoing'|'upcoming'
function MatchUtil.computeMatchPhase(match)
	-- TODO: a dateIsExact of false becomes nil here, so it is treated as unknown rather than as
	-- inexact, and a past match with dateIsExact = false reads as ongoing instead of upcoming.
	-- Only the record spelling (dateexact = '0') currently makes a match inexact.
	local isExact = Logic.readBoolOrNil(match.dateIsExact or match.dateexact)
	local matchStartTimestamp = match.timestamp or Date.readTimestampOrNil(match.date) or Date.defaultTimestamp
	if match.winner or Logic.readBool(match.finished) then
		return 'finished'
	elseif isExact ~= false and matchStartTimestamp ~= Date.defaultTimestamp and matchStartTimestamp <= NOW then
		return 'ongoing'
	else
		return 'upcoming'
	end
end

return MatchUtil

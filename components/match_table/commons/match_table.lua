---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Team = require('Module:Team')

local PlayerExt = Lua.import('Module:Player/Ext')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local PLAYER_MODE = 'player'
local TEAM_MODE = 'team'
local UTC = 'UTC'
local DRAW = 'draw'

---@alias MatchTableMode `PLAYER_MODE` | `TEAM_MODE`

---@class MatchTableConfig
---@field mode MatchTableMode
---@field limit number?
---@field overallStats boolean
---@field displayGameIcons boolean
---@field showResult boolean
---@field includeAllGames boolean
---@field opponent standardOpponent
---@field aliases table<string, true>
---@field timeRange {startDate: number, endDate: number}

---@class MatchTableMatch
---@field timestamp number
---@field timeIsExact boolean
---@field timeZone string
---@field liquipediatier string?
---@field liquipediatiertype string?
---@field displayName string
---@field icon string?
---@field iconDark string?
---@field pageName string
---@field vods {index: number, link: string}[]
---@field type string
---@field result MatchTableMatchResult

---@class MatchTableMatchResult
---@field opponent table #match2opponent table
---@field vs table #match2opponent table
---@field winner number
---@field resultType string?
---@field countGames boolean

---@class MatchTable
---@operator call(table): MatchTable
---@field args table
---@field title Title
---@field config MatchTableConfig
---@field matches MatchTableMatch[]
---@field stats {matches: {w: number, d: number, l: number}, games: {w: number, d: number, l: number}}
---@field display Html
local MatchTable = Class.new(function(self, args)
	self.args = args or {}
	self.title = mw.title.getCurrentTitle()
end)

---@return self
function MatchTable:init()
	local args = self.args

	local mode = args.tableMode
	assert(mode == PLAYER_MODE or mode == TEAM_MODE, 'Unsupported "|tableMode=" input')

	self.config = {
		mode = mode,
		limit = tonumber(args.limit),
		overallStats = Logic.readBool(args.overallStats),
		displayGameIcons = Logic.readBool(args.gameIcons),
		showResult = Logic.nilOr(Logic.readBoolOrNil(args.showResult), true),
		includeAllGames = Logic.nilOr(Logic.readBoolOrNil(args.includeAllGames), true),
		opponent = self:readOpponent(mode),
		timeRange = self:readTimeRange(),
		aliases = {}, -- shut up anno warning
	}
	self.config.aliases = self:readAliases(mode)

	return self
end

---@param mode MatchTableMode
---@return standardOpponent
function MatchTable:readOpponent(mode)
	if mode == PLAYER_MODE then
		local player = {displayName = self.args.player or self.title.rootText}
		PlayerExt.populatePageName(player)
		return {type = 'solo', players = {player}}
	end

	local team = self.args.team or self.title.namespace == 0 and self.title.rootText or nil
	assert(team, 'Required team= argument')

	return {type = 'team', template = team:lower():gsub('_', ' ')}
end

---@param mode MatchTableMode
---@return string[]
function MatchTable:readAliases(mode)
	local aliases = {}
	Array.mapIndexes(function(aliasIndex)
		local alias = self.args['alias' .. aliasIndex]:gsub(' ', '_')
		local aliasWithSpaces = alias:gsub('_', ' ')
		aliases[alias] = true
		aliases[aliasWithSpaces] = true
	end)

	if mode == PLAYER_MODE then
		local name = self.config.opponent.players[1].pageName:gsub(' ', '_')
		local nameWithSpaces = name:gsub('_', ' ')
		aliases[name] = true
		aliases[nameWithSpaces] = true

		return aliases
	end

	--for team matches also query pagenames from team template
	local opponentNames = Team.queryHistoricalNames(self.config.opponent.template)
	Array.forEach(opponentNames, function(name)
		name = name:gsub(' ', '_')
		local nameWithSpaces = name:gsub('_', ' ')
		aliases[name] = true
		aliases[nameWithSpaces] = true
	end)

	return aliases
end

---@return {startDate: number, endDate: number}
function MatchTable:readTimeRange()
	local args = self.args
	local yearsString = args.years or self.title.prefixedText:match('/Matches/([%w-]+)$')
	if args.sdate or args.edate or not yearsString then
		return {
			startDate = DateExt.readTimestamp(args.sdate) or DateExt.minTimestamp,
			endDate = DateExt.readTimestamp(args.edate) or DateExt.maxTimestamp,
		}
	end

	--build year range from subpage name (or input)
	local yearRange = Array.map(mw.text.split(yearsString, '-'), String.trim)
	yearRange = {
		tonumber(yearRange[1]),
		tonumber(yearRange[2] or yearRange[1]),
	}

	--sort
	if (yearRange[1] and yearRange[2] and yearRange[2] < yearRange[1]) or (yearRange[2] and not yearRange[1]) then
		yearRange = {yearRange[2], yearRange[1]}
	end

	return {
		startDate = yearRange[1] and DateExt.readTimestamp(yearRange[1] .. '-01-01') or DateExt.minTimestamp,
		endDate = yearRange[1] and DateExt.readTimestamp((yearRange[1] + 1) .. '-01-01') or DateExt.maxTimestamp,
	}
end

---@return self
function MatchTable:query()
	self.matches = {}
	Lpdb.executeMassQuery('match2', {
		conditions = self:buildConditions(),
		order = 'date desc',
		query = 'match2opponents, match2games, date, dateexact, icon, icondark, liquipediatier, game, type, '
			.. 'liquipediatiertype, tournament, parent, pagename, vod, winner, walkover, resulttype, extradata',
	}, function(match)
		table.insert(self.matches, self:matchFromRecord(match))
	end, self.config.limit)

	self.stats = self:statsFromMatches()

	return self
end

---@return string
function MatchTable:buildConditions()
	return ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('finished'), Comparator.eq, 1)}
		:add{self:buildDateConditions()}
		:add{self:buildOpponentConditions()}
		:toString()
end

---@return ConditionTree
function MatchTable:buildDateConditions()
	local timeRange = self.config.timeRange

	local conditions = ConditionTree(BooleanOperator.all)

	if timeRange.startDate ~= DateExt.minTimestamp then
		conditions:add{ConditionNode(ColumnName('date'), Comparator.gt, DateExt.formatTimestamp('c', timeRange[1] - 1))}
	end

	if timeRange.endDate ~= DateExt.maxTimestamp then
		conditions:add{ConditionNode(ColumnName('date'), Comparator.lt, DateExt.formatTimestamp('c', timeRange[2]))}
	end

	return conditions
end

---@return ConditionTree
function MatchTable:buildOpponentConditions()
	local conditions = ConditionTree(BooleanOperator.any)
	Array.forEach(Array.extractKeys(self.config.aliases), function(alias)
		conditions:add{ConditionNode(ColumnName('opponent'), Comparator.eq, alias)}
	end)

	return conditions
end

---@param record table
---@return MatchTableMatch?
function MatchTable:matchFromRecord(record)
	local result = self:resultFromRecord(record)
	if not result then
		return
	end

	record.extradata = record.extradata or {}

	return {
		timestamp = record.extradata.timestamp or DateExt.readTimestamp(record.date),
		timeIsExact = Logic.readBool(record.dateexact),
		timeZone = record.extradata.timezoneid or UTC,
		liquipediatier = record.liquipediatier,
		liquipediatiertype = record.liquipediatiertype,
		displayName = String.nilIfEmpty(record.tournament) or record.pagename:gsub('_', ' '),
		icon = String.nilIfEmpty(record.icon),
		iconDark = String.nilIfEmpty(record.icondark),
		pageName = String.nilIfEmpty(record.parent) or String.nilIfEmpty(record.pagename),
		vods = self:vodsFromRecord(record),
		type = record.type,
		result = result,
	}
end

---@param record table
---@return {index: number, link: string}[]
function MatchTable:vodsFromRecord(record)
	local vods = {}
	if String.nilIfEmpty(record.vod) then
		vods = {{index = 0, link = record.vod}}
	end

	Array.forEach(record.match2games, function(game, gameIndex)
		if String.nilIfEmpty(game.vod) then
			table.insert(vods, {link = game.vod, index = gameIndex})
		end
	end)

	return vods
end

---@param record table
---@return MatchTableMatchResult?
function MatchTable:resultFromRecord(record)
	if #record.match2opponents[1] ~= 2 then
		return self:resultFromNonStandardRecord(record)
	end

	local aliases = self.config.aliases
	local countGames = false

	local foundInAlias = function(opponentRecord)
		if aliases[opponentRecord.name] then
			countGames = true
			return true
		end
		return self.config.mode == PLAYER_MODE and Array.any(opponentRecord.match2players, function(player)
			return aliases[player.name] or false
		end)
	end

	local winner = tonumber(record.winner)
	local indexes
	if foundInAlias(record.match2opponents[1]) then
		indexes = {1, 2}
	elseif foundInAlias(record.match2opponents[2]) then
		indexes = {2, 1}
		winner = winner == 2 and 1 or winner == 1 and 2 or winner
	else
		mw.ext.TeamLiquidIntegration.add_category('MatchesTables with invalid matches')
		mw.logObject(record)
		return
	end

	local result = {
		opponent = record.match2opponents[indexes[1]],
		vs = record.match2opponents[indexes[2]],
		winner = winner,
		resultType = record.resultType,
		countGames = countGames,
	}

	return result
end

---overwritable for wikis that have BR/FFA matches
---@param record table
---@return table?
function MatchTable:resultFromNonStandardRecord(record)
end

---@return {matches: {w: number, d: number, l: number}, games: {w: number, d: number, l: number}}
function MatchTable:statsFromMatches()
	local totalMatches = {w = 0, d = 0, l = 0}
	local totalGames = {w = 0, d = 0, l = 0}

	local nonNegative = function(value)
		return math.max(tonumber(value) or 0, 0)
	end

	Array.forEach(self.matches, function(match)
		if match.result.resultType == DRAW then
			totalMatches.d = totalMatches.d + 1
		elseif match.result.winner == 1 then
			totalMatches.w = totalMatches.w + 1
		elseif match.result.winner == 2 then
			totalMatches.l = totalMatches.l + 1
		end

		if match.result.countGames or not self.config.includeAllGames then
			totalGames.w = totalGames.w + nonNegative(match.result.opponent.score)
			totalGames.l = totalGames.l + nonNegative(match.result.vs.score)
		end
	end)

	return {
		matches = totalMatches,
		games = totalGames,
	}
end

---@return Html
function MatchTable:build()

end

--todo: display, incl. overall stats (runtime issues???)

return MatchTable

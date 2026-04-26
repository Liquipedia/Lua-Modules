---
-- @Liquipedia
-- page=Module:FactionStatistics/Player
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MatchupDisplay = Lua.import('Module:FactionStatistics/MatchupDisplay')
local Opponent = Lua.import('Module:Opponent/Custom')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local Box = Lua.import('Module:Widget/Basic/Box')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_TIERS = {1, 2}
local DEFAULT_TIER_TYPE = 'Unset'
local SUM_ABBR = HtmlWidgets.Abbr{title = 'Sum of', children = 'Σ'}

---@class StormgatePlayerMatchupStatistics
---@operator call(table): StormgatePlayerMatchupStatistics
---@field args table<string, string>
---@field matchIds string[]
---@field player string
---@field versus string?
---@field byFaction table<string, {w: integer, l: integer}>
---@field byType {online: {w: integer, l: integer}, offline: {w: integer, l: integer}}
---@field byBestof table<string, {w: integer, l: integer}>
---@field byOpponentType table<OpponentType, {w: integer, l: integer}>
---@field byMap table<string, table<string, {w: integer, l: integer}>>
---@field total {w: integer, l: integer}
local PlayerStatistics = Class.new(function(self, args) self:init(args) end)

---@param frame Frame
---@return Widget|string
function PlayerStatistics.run(frame)
	local args = Arguments.getArgs(frame)

	return PlayerStatistics(args):query():create()
end

---@param args table
---@return self
function PlayerStatistics:init(args)
	self.args = args
	assert(args.player, 'No player specified')
	self.player = Page.pageifyLink(self.args.player)

	if Logic.isNotEmpty(self.args.versus) then
		self.versus = Page.pageifyLink(self.args.versus)
	end

	return self
end

---@return self
function PlayerStatistics:query()
	self:_getMatchData()
	if Logic.isEmpty(self.matchIds) then return self end
	self:_getMapData()

	return self
end

function PlayerStatistics:_getMatchData()
	self.matchIds = {}

	self.byFaction = PlayerStatistics._newEmptyFactionData()
	self.byType = {online = {w = 0, l = 0}, offline = {w = 0, l = 0}}
	self.byBestof = {}
	self.byOpponentType = {}

	---@param opponents table[]
	---@param winner integer?
	---@return boolean
	local shouldExclude = function(opponents, winner)
		return winner ~= 1 and winner ~= 2
			or not opponents[1]
			or not opponents[1]
			or #opponents ~= 2
			or Array.any(opponents, function(opponent)
				return opponent.status and opponent.status ~= 'S'
			end)
	end

	Lpdb.executeMassQuery('match2', {
		conditions = self:_getMatchConditions(),
		query = 'match2id, bestof, match2opponents, winner, type',
	}, function (record)
		local winner = tonumber(record.winner)
		local opponents = record.match2opponents

		if shouldExclude(opponents, winner) then return end

		table.insert(self.matchIds, record.match2id)

		local side = (opponents[1].name == self.player or Array.any(opponents[1].match2players or {}, function(playerObj)
			return playerObj.name == self.player
		end)) and 1 or 2

		local vsSide = 3 - side
		local result = side == winner and 'w' or 'l'

		local eventType = string.lower(record.type or '') == 'offline' and 'offline' or 'online'
		self.byType[eventType][result] = self.byType[eventType][result] + 1

		local opponentType = opponents[vsSide].type
		self.byOpponentType[opponentType] = self.byOpponentType[opponentType] or {w = 0, l = 0}
		self.byOpponentType[opponentType][result] = self.byOpponentType[opponentType][result] + 1

		local bestof = tostring(tonumber(record.bestof) or -1)
		self.byBestof[bestof] = self.byBestof[bestof] or {w = 0, l = 0}
		self.byBestof[bestof][result] = self.byBestof[bestof][result] + 1

		if Array.any(opponents, function(opponent) return opponent.type ~= Opponent.solo end) then return end

		self.byFaction.total[result] = self.byFaction.total[result] + 1

		local vsFaction = Logic.emptyOr(
			(((opponents[vsSide].match2players or {})[1] or {}).extradata or {}).faction,
			Faction.defaultFaction
		)
		if vsFaction == Faction.defaultFaction then return end

		self.byFaction[vsFaction][result] = self.byFaction[vsFaction][result] + 1
	end)
end

---@return string
function PlayerStatistics:_getMatchConditions()
	local args = self.args

	local tiers = Array.map(Array.parseCommaSeparatedString(args.tiers), function(num)
		return tonumber(num)
	end)
	tiers = Logic.nilIfEmpty(tiers) or DEFAULT_TIERS

	local tierTypes = Array.parseCommaSeparatedString(args.tiers or '!Qualifier')
	tierTypes = Array.map(tierTypes, function(tierType)
		return tierType == DEFAULT_TIER_TYPE and '' or tierType
	end)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('finished'), Comparator.eq, 1), -- only finished matches
		ConditionNode(ColumnName('winner'), Comparator.neq, ''), -- expect a winner
		ConditionNode(ColumnName('status'), Comparator.neq, 'notplayed'), -- i.e. ignore not played matches
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate), --i.e. wrongly set up
		ConditionUtil.anyOf(ColumnName('liquipediatier'), tiers),
		ConditionUtil.anyOf(ColumnName('liquipediatiertype'), tierTypes),
	}

	local startDate = DateExt.readTimestamp(args.sdate)
	if startDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.ge, startDate))
	end

	local endDate = DateExt.readTimestamp(args.edate)
	if endDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.le, endDate))
	end

	if self.versus then
		conditions:add{
			ConditionNode(ColumnName('opponent'), Comparator.eq, self.player),
			ConditionNode(ColumnName('opponent'), Comparator.eq, self.versus),
		}
	elseif Logic.readBool(args.onlySolo) then
		conditions:add(ConditionNode(ColumnName('opponent'), Comparator.eq, self.player))
	else
		conditions:add(ConditionNode(ColumnName('player'), Comparator.eq, self.player))
	end

	return tostring(conditions)
end

---@return table<string, {w: integer, l: integer}>
function PlayerStatistics._newEmptyFactionData()
	return Table.map(Array.append(Faction.knownFactions, 'total'), function(index, key)
		return key, {w = 0, l = 0}
	end)
end

function PlayerStatistics:_getMapData()
	local player = self.player

	local byMap = {total = PlayerStatistics._newEmptyFactionData()}

	---@param opponent table
	---@return boolean
	local hasNonScoreStatusOrInvalidNumberOfPlayers = function(opponent)
		return opponent.status and opponent.status ~= 'S'
			or #opponent.players ~= 1
	end

	---@param opponents table[]
	---@param winner integer?
	---@return string?
	---@return string?
	local getResult = function(opponents, winner)
		if Array.any(opponents, hasNonScoreStatusOrInvalidNumberOfPlayers) then
			return
		end

		local player1 = opponents[1].players[1].player
		local faction1 = opponents[1].players[1].faction
		local player2 = opponents[2].players[1].player
		local faction2 = opponents[2].players[1].faction

		if player == player1 and winner == 1 then
			return 'w', faction2
		elseif player == player2 and winner == 2 then
			return 'w', faction1
		elseif player == player1 and winner == 2 then
			return 'l', faction2
		elseif player == player2 and winner == 1 then
			return 'l', faction1
		end
	end

	---@param record match2game
	local processGame = function(record)
		local result, vsFaction = getResult(record.opponents, tonumber(record.winner))
		if not result then return end

		byMap.total.total[result] = byMap.total.total[result] + 1

		if vsFaction and vsFaction ~= Faction.defaultFaction then
			byMap.total[vsFaction][result] = byMap.total[vsFaction][result] + 1
		end

		local map = Logic.nilIfEmpty(record.map)
		if not map then
			return
		end

		byMap[map] = byMap[map] or PlayerStatistics._newEmptyFactionData()
		byMap[map].total[result] = byMap[map].total[result] + 1

		if vsFaction and vsFaction ~= Faction.defaultFaction then
			byMap[map][vsFaction][result] = byMap[map][vsFaction][result] + 1
		end
	end

	Lpdb.executeMassQuery('match2game', {
		conditions = self:_getMapConditions(),
		query = 'map, extradata, opponents, winner',
	}, processGame)

	self.byMap = byMap
end

---@return string
function PlayerStatistics:_getMapConditions()
	---@param opponent string
	---@return ConditionTree
	local toOpponentCondition = function(opponent)
		return ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('opponent1', 'extradata'), Comparator.eq, opponent),
			ConditionNode(ColumnName('opponent2', 'extradata'), Comparator.eq, opponent),
		}
	end

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('winner'), Comparator.neq, ''), -- expect a winner
		ConditionNode(ColumnName('status'), Comparator.neq, 'notplayed'), -- i.e. ignore not played maps
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDate), --i.e. wrongly set up
		toOpponentCondition(self.player),
		ConditionUtil.anyOf(ColumnName('match2id'), self.matchIds),
		self.versus and toOpponentCondition(self.versus) or nil,
	}

	return tostring(conditions)
end

---@return Widget|string
function PlayerStatistics:create()
	if Logic.isEmpty(self.matchIds) then
		return 'No data found'
	end

	return Box{
		children = {
			self:_matchesPerFaction(),
			self:_matchesPerType(),
			self:_matchesPerOpponentType(),
			self:_matchesPerBestof(),
			self:_gamesPerMapAndFaction()
		},
	}
end

---@return Widget
function PlayerStatistics:_matchesPerFaction()
	local display = function(key)
		return {
			'vs. ',
			key == 'total' and 'All' or Faction.Icon{faction = key},
		}
	end

	-- can not use Array.extend due to the metatable ... see #7433
	local order = {'total'}
	Array.forEach(Faction.knownFactions, function(faction) table.insert(order, faction) end)

	return PlayerStatistics._simpleTable(self.byFaction, display, order, 'Matches per Faction')
end

---@return Widget
function PlayerStatistics:_matchesPerType()
	local order = {'offline', 'online'}
	return PlayerStatistics._simpleTable(self.byType, String.upperCaseFirst, order, 'Matches per Environment')
end

---@return Widget
function PlayerStatistics:_matchesPerOpponentType()
	local order = {
		Opponent.solo,
		Opponent.team,
		Opponent.duo,
		Opponent.trio,
		Opponent.quad,
	}
	return PlayerStatistics._simpleTable(self.byOpponentType, String.upperCaseFirst, order, 'Matches per Opponent-Type')
end

---@return Widget
function PlayerStatistics:_matchesPerBestof()
	local display = function(key)
		if key == '-1' then
			return 'Unknown'
		end
		return HtmlWidgets.Abbr{title = 'Best of ' .. key, children = 'Bo' .. key}
	end
	local order = Array.extractKeys(self.byBestof)
	Array.sortInPlaceBy(order, tonumber, function(a, b)
		return b == -1 or (a ~= -1 and a < b)
	end)
	return PlayerStatistics._simpleTable(self.byBestof, display, order, 'Matches per Environment')
end

---@param data table<string, {w: integer, l: integer}>
---@param display fun(string): Renderable
---@param order string[]
---@param title string
---@return Widget
function PlayerStatistics._simpleTable(data, display, order, title)
	local rows = Array.map(order, function(key)
		local matchupData = data[key]
		if not matchupData or (matchupData.w + matchupData.l == 0) then return end
		return TableWidgets.Row{
			children = WidgetUtil.collect(
				TableWidgets.Cell{children = display(key)},
				MatchupDisplay.display(matchupData)
			)
		}
	end)

	return TableWidgets.Table{
		sortable = false,
		caption = title,
		columns = WidgetUtil.collect(
			{align = 'left'},
			Array.rep({align = 'right'}, 4)
		),
		children = {
			PlayerStatistics._header(true),
			TableWidgets.TableBody{children = rows},
		},
	}
end

---@param emptyCell boolean?
---@return Widget
function PlayerStatistics._header(emptyCell)
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			emptyCell and TableWidgets.CellHeader{children = ''} or nil,
			TableWidgets.CellHeader{children = SUM_ABBR},
			TableWidgets.CellHeader{children = 'W'},
			TableWidgets.CellHeader{children = 'L'},
			TableWidgets.CellHeader{children = '%'}
		)
	}
end

---@return Widget
function PlayerStatistics:_gamesPerMapAndFaction()
end

return PlayerStatistics

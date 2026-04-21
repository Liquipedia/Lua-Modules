---
-- @Liquipedia
-- page=Module:MatchTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Game = Lua.import('Module:Game')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local I18n = Lua.import('Module:I18n')
local Info = Lua.import('Module:Info', {loadData = true})
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Math = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tournament = Lua.import('Module:Tournament')
local Tier = Lua.import('Module:Tier/Custom')
local VodLink = Lua.import('Module:VodLink')

local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Link = Lua.import('Module:Widget/Basic/Link')
local MatchPageButton = Lua.import('Module:Widget/Match/PageButton')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WinLossIndicator = Lua.import('Module:Widget/Match/Summary/GameWinLossIndicator')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local DRAW_WINNER = 0
local INVALID_TIER_DISPLAY = 'Undefined'
local INVALID_TIER_SORT = 'ZZ'
local SCORE_STATUS = 'S'
local SCORE_CONCAT = '&nbsp;&#58;&nbsp;'
local BO1_SCORE_CONCAT = '&nbsp;-&nbsp;'
local SECONDS_ONE_DAY = 3600 * 24

---@alias MatchTableMode `Opponent.solo` | `Opponent.team` | 'playersOfTeam'
---@alias WDLCount {w: number, d: number, l: number}

---@class MatchTableConfig
---@field mode MatchTableMode
---@field limit number?
---@field dateFormat ('full'|'compact')?
---@field displayGameIcons boolean
---@field opponentHeader string?
---@field showResult boolean
---@field aliases table<string, true>
---@field addCategory boolean
---@field vs table<string, true>
---@field timeRange {startDate: number, endDate: number}
---@field title string?
---@field showTier boolean
---@field showIcon boolean
---@field showVod boolean
---@field showMatchPage boolean
---@field matchPageButtonText 'full'|'short'|'hide'
---@field showStats boolean
---@field showOnlyGameStats boolean
---@field showRoundStats boolean
---@field showOpponent boolean
---@field queryHistoricalAliases boolean
---@field showType boolean
---@field showYearHeaders boolean
---@field sortableResults boolean
---@field useTickerName boolean
---@field teamStyle teamStyle
---@field linkSubPage boolean

---@class MatchTableMatch: MatchGroupUtilMatch
---@field displayName string
---@field pageName string
---@field vods {index: number, link: string}[]
---@field result MatchTableMatchResult

---@class MatchTableMatchResult
---@field opponent standardOpponent
---@field gameOpponents table[]
---@field vs standardOpponent
---@field gameVsOpponents table[]
---@field winner number?
---@field flipped boolean
---@field countGames boolean
---@field countRounds boolean

---@class MatchTableStats
---@field matches {w: number, d: number, l: number}
---@field games {w: number, d: number, l: number}
---@field rounds {w: number, d: number, l: number}

---@class MatchTable
---@operator call(table): MatchTable
---@field args table
---@field title Title
---@field config MatchTableConfig
---@field matches MatchTableMatch[]
---@field stats MatchTableStats
local MatchTable = Class.new(function(self, args)
	self.args = args or {}
	self.title = mw.title.getCurrentTitle()
end)

---@return self
function MatchTable:readConfig()
	local args = self.args

	local mode = args.tableMode
	assert(mode == Opponent.solo or mode == Opponent.team, 'Unsupported "|tableMode=" input')

	local opponents = self:_readOpponents(mode)

	self.config = Table.merge(self:_readDefaultConfig(), {
		aliases = self:readAliases(mode),
		vs = {},
		showOpponent = Logic.nilOr(Logic.readBoolOrNil(args.showOpponent), #opponents > 1 or mode == Opponent.solo),
		queryHistoricalAliases = not Logic.readBool(args.skipQueryingHistoricalAliases)
	})

	Array.forEach(opponents, function(opponent)
		Table.mergeInto(self.config.aliases, self:getOpponentAliases(mode, opponent))
	end)

	local vsMode = args.vsMode or mode
	assert(vsMode == Opponent.solo or vsMode == Opponent.team, 'Unsupported "|vsMode=" input')

	Array.forEach(self:_readVsOpponents(mode), function(opponent)
		Table.mergeInto(self.config.vs, self:getOpponentAliases(mode, opponent))
	end)

	return self
end

function MatchTable:_readDefaultConfig()
	local args = self.args

	return {
		addCategory = Logic.nilOr(Logic.readBoolOrNil(args.addCategory), true),
		mode = args.tableMode,
		limit = tonumber(args.limit),
		dateFormat = args.dateFormat,
		displayGameIcons = Logic.readBool(args.gameIcons),
		opponentHeader = Logic.nilIfEmpty(args.opponentHeader),
		showResult = Logic.nilOr(Logic.readBoolOrNil(args.showResult), true),
		timeRange = self:readTimeRange(),
		title = args.title,
		showTier = not Logic.readBool(args.hide_tier),
		showIcon = not Logic.readBool(args.hide_icon),
		showVod = Logic.readBool(args.vod),
		showStats = Logic.nilOr(Logic.readBoolOrNil(args.stats), true),
		showOnlyGameStats = Logic.readBool(args.showOnlyGameStats),
		showRoundStats = Logic.readBool(args.showRoundStats),
		showType = Logic.readBool(args.showType),
		showYearHeaders = Logic.readBool(args.showYearHeaders),
		sortableResults = Logic.nilOr(Logic.readBoolOrNil(args.sortableResults), true),
		useTickerName = Logic.readBool(args.useTickerName),
		teamStyle = String.nilIfEmpty(args.teamStyle) or 'short',
		linkSubPage = Logic.readBool(args.linkSubPage),
		showMatchPage = Info.config.match2.matchPage,
		matchPageButtonText = args.matchPageButtonText,
	}
end

---@param mode MatchTableMode
---@return standardOpponent[]
function MatchTable:_readOpponents(mode)
	if mode == 'playersOfTeam' then
		return Array.map(self:_fetchPlayersOnTeam(), function(input) return self:_readOpponent(mode, input) end)
	end

	local base = mode == Opponent.solo and 'player' or 'team'
	local inputs = self:_readOpponentInputsFromBase(base)

	if Logic.isEmpty(inputs) then
		assert(self.title.namespace == 0, 'Required ' .. base .. '= argument')
		table.insert(inputs, self.title.rootText)
	end

	return Array.map(inputs, function(input) return self:_readOpponent(mode, input) end)
end

---@return string[]
function MatchTable:_fetchPlayersOnTeam()
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('status'), Comparator.eq, 'active'),
		ConditionNode(ColumnName('pagename'), Comparator.eq, self.args.team or self.title.rootText),
	}

	local squadPlayers = mw.ext.LiquipediaDB.lpdb('squadplayer', {
		limit = 5000,
		conditions = tostring(conditions),
		query = 'link'
	})

	return Array.map(squadPlayers, Operator.property('link'))
end

---@param mode MatchTableMode
---@return standardOpponent[]
function MatchTable:_readVsOpponents(mode)
	local inputs = self:_readOpponentInputsFromBase('vs' .. (mode == Opponent.solo and 'player' or 'team'))

	return Array.map(inputs, function(input) return self:_readOpponent(mode, input) end)
end

---@param base string
---@return string[]
function MatchTable:_readOpponentInputsFromBase(base)
	local inputs = Array.extractValues(Table.filterByKey(self.args, function(key)
		return key:find('^' .. base .. '%d*$') ~= nil
	end))

	if Logic.isNotEmpty(inputs) or Logic.isEmpty(self.args[base .. 's']) then return inputs end

	return Array.parseCommaSeparatedString(self.args[base .. 's'])
end

---@param mode MatchTableMode
---@param input string
---@return standardOpponent
function MatchTable:_readOpponent(mode, input)
	if mode == Opponent.solo or mode == 'playersOfTeam' then
		local player = {pageName = input}
		PlayerExt.populatePageName(player)
		return {type = 'solo', players = {player}}
	end

	return {type = 'team', template = input:lower():gsub('_', ' ')}
end

---@param mode MatchTableMode
---@return string[]
function MatchTable:readAliases(mode)
	local aliases = {}
	if String.isEmpty(self.args.aliases) then return aliases end

	local aliasInput = Array.parseCommaSeparatedString(self.args.aliases)

	Array.forEach(aliasInput, function(alias)
		alias = alias:gsub(' ', '_')
		local aliasWithSpaces = alias:gsub('_', ' ')
		aliases[alias] = true
		aliases[aliasWithSpaces] = true
	end)

	return aliases
end

---@param mode MatchTableMode
---@param opponent standardOpponent
---@return string[]
function MatchTable:getOpponentAliases(mode, opponent)
	if mode == Opponent.solo then
		local name = opponent.players[1].pageName:gsub(' ', '_')
		local nameWithSpaces = name:gsub('_', ' ')

		return {
			[name] = true,
			[nameWithSpaces] = true,
		}
	end

	local aliases = {}
	--for teams also query pagenames from team template
	---@type string[]
	local opponentNames = self.config.queryHistoricalAliases
		and Array.map(TeamTemplate.queryHistoricalNames(opponent.template), TeamTemplate.getPageName)
		or {opponent.template}

	Array.forEach(opponentNames, function(name)
		name = name:gsub(' ', '_')
		local nameWithSpaces = name:gsub('_', ' ')
		local pagifiedName = Page.pageifyLink(name) --[[@as string]]
		local pagifiedNameWithSpaces = pagifiedName:gsub('_', ' ')
		aliases[name] = true
		aliases[nameWithSpaces] = true
		aliases[pagifiedName] = true
		aliases[pagifiedNameWithSpaces] = true
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
	local yearInput = Array.parseCommaSeparatedString(yearsString, '-')
	local yearRange = {
		tonumber(yearInput[1]),
		tonumber(yearInput[2] or yearInput[1]),
	}

	--sort
	if (yearRange[1] and yearRange[2] and yearRange[2] < yearRange[1]) or (yearRange[2] and not yearRange[1]) then
		yearRange = {yearRange[2], yearRange[1]}
	end

	return {
		startDate = yearRange[1] and DateExt.readTimestamp(yearRange[1] .. '-01-01') or DateExt.minTimestamp,
		endDate = yearRange[2] and DateExt.readTimestamp((yearRange[2] + 1) .. '-01-01') or DateExt.maxTimestamp,
	}
end

---@return self
function MatchTable:query()
	self.matches = {}

	Lpdb.executeMassQuery('match2', {
		conditions = tostring(self:buildConditions()),
		order = 'date desc',
		query = 'match2id, match2opponents, match2games, date, dateexact, icon, icondark, liquipediatier, game, type,'
			.. 'liquipediatiertype, tournament, pagename, parent, section, tickername, vod, winner, match2bracketdata,'
			.. 'extradata, bestof, publishertier',
		limit = 50,
	}, function(match)
		table.insert(self.matches, self:matchFromRecord(match) or nil)
	end, self.config.limit)

	if (
		self.config.limit and self.config.limit == #self.matches and
		not self.config.linkSubPage and self.config.addCategory
	) then
		mw.ext.TeamLiquidIntegration.add_category('Limited match pages')
	end

	self.stats = self:statsFromMatches()

	return self
end

---@return ConditionTree
function MatchTable:buildConditions()
	return ConditionTree(BooleanOperator.all)
		:add(ConditionNode(ColumnName('finished'), Comparator.eq, 1))
		:add(self:buildDateConditions())
		:add(self:buildOpponentConditions())
		:add(self:buildAdditionalConditions())
end

---@return ConditionTree?
function MatchTable:buildDateConditions()
	local timeRange = self.config.timeRange

	if timeRange.startDate == DateExt.minTimestamp and timeRange.endDate == DateExt.maxTimestamp then
		return
	end

	local conditions = ConditionTree(BooleanOperator.all)

	if timeRange.startDate ~= DateExt.minTimestamp then
		conditions:add{ConditionNode(ColumnName('date'), Comparator.gt,
			DateExt.formatTimestamp('c', timeRange.startDate - 1))}
	end

	if timeRange.endDate ~= DateExt.maxTimestamp then
		conditions:add{ConditionNode(ColumnName('date'), Comparator.lt,
			DateExt.formatTimestamp('c', timeRange.endDate + SECONDS_ONE_DAY))}
	end

	return conditions
end

---@return ConditionTree
function MatchTable:buildOpponentConditions()
	local columnName = self.config.mode == Opponent.solo and 'player' or 'opponent'

	local opponentConditions = ConditionTree(BooleanOperator.any)
	Array.forEach(Array.extractKeys(self.config.aliases), function(alias)
		opponentConditions:add{ConditionNode(ColumnName(columnName), Comparator.eq, alias)}
	end)

	if Logic.isEmpty(self.config.vs) then
		return opponentConditions
	end

	local vsConditions = ConditionTree(BooleanOperator.any)
	Array.forEach(Array.extractKeys(self.config.vs), function(alias)
		vsConditions:add{ConditionNode(ColumnName('opponent'), Comparator.eq, alias)}
	end)

	return ConditionTree(BooleanOperator.all)
		:add(opponentConditions)
		:add(vsConditions)
end

---@return ConditionTree?
function MatchTable:buildAdditionalConditions()
	local args = self.args
	local conditions = ConditionTree(BooleanOperator.all):add(
		ConditionNode(ColumnName('status'), Comparator.neq, 'notplayed')
	)

	local getOrCondition = function(lpdbKey, input)
		if Logic.isEmpty(input) then return end

		conditions:add(ConditionUtil.anyOf(ColumnName(lpdbKey), Array.parseCommaSeparatedString(input)))
	end

	getOrCondition('liquipediatier', args.tier)
	getOrCondition('game', args.game)

	if Logic.isNotEmpty(args.bestof) then
		conditions:add(ConditionNode(ColumnName('bestof'), Comparator.eq, args.bestof))
	end

	if Logic.isNotEmpty(args.type) then
		conditions:add(ConditionNode(ColumnName('type'), Comparator.eq, args.type))
	end

	return conditions
end

---@param record match2
---@return MatchTableMatch?
function MatchTable:matchFromRecord(record)
	local match = MatchGroupUtil.matchFromRecord(record) --[[@as MatchTableMatch]]
	local result = self:resultFromRecord(match)
	if not result then
		return
	end

	match.result = result
	match.vods = self:vodsFromRecord(match)

	local tournament = Tournament.partialTournamentFromMatch(match)

	match.displayName = (match.section ~= 'Results' and #match.opponents <= 2) and table.concat({
		tournament.displayName,
		'-',
		match.section
	}, ' ') or tournament.displayName
	match.pageName = mw.title.makeTitle(0, match.pageName, match.section).fullText

	return match
end

---@param record MatchGroupUtilMatch
---@return {index: number, link: string}[]
function MatchTable:vodsFromRecord(record)
	local vods = {}
	if String.nilIfEmpty(record.vod) then
		vods[1] = {index = 0, link = record.vod}
	end

	Array.forEach(record.games, function(game, gameIndex)
		if String.isNotEmpty(game.vod) then
			table.insert(vods, {link = game.vod, index = gameIndex})
		end
	end)

	return vods
end

---@param record MatchGroupUtilMatch
---@return MatchTableMatchResult?
function MatchTable:resultFromRecord(record)
	if #record.opponents ~= 2 then
		return self:resultFromNonStandardRecord(record)
	end

	local aliases = self.config.aliases
	local countGames = false
	local countRounds = false

	---@param opponentRecord standardOpponent
	---@return boolean
	local foundInAlias = function(opponentRecord)
		if aliases[opponentRecord.name] then
			countGames = true
			countRounds = self.config.showRoundStats
			return true
		end
		return self.config.mode == Opponent.solo and Array.any(opponentRecord.players, function(player)
			return aliases[player.pageName] or false
		end)
	end

	local winner = record.winner
	local flipped = false
	local indexes
	if foundInAlias(record.opponents[1]) then
		indexes = {1, 2}
	elseif foundInAlias(record.opponents[2]) then
		indexes = {2, 1}
		flipped = true
		winner = winner == 2 and 1 or winner == 1 and 2 or winner
	else
		mw.ext.TeamLiquidIntegration.add_category('MatchesTables with invalid matches')
		mw.logObject(record)
		return
	end

	local gameOpponents = Array.map(record.games, Operator.property('opponents'))

	---@type MatchTableMatchResult
	local result = {
		opponent = record.opponents[indexes[1]],
		vs = record.opponents[indexes[2]],
		winner = winner,
		flipped = flipped,
		countGames = countGames,
		countRounds = countRounds,
		gameOpponents = Array.map(gameOpponents, Operator.property(indexes[1])),
		gameVsOpponents = Array.map(gameOpponents, Operator.property(indexes[2]))
	}

	return result
end

---overwritable for wikis that have BR/FFA matches
---@param record MatchGroupUtilMatch
---@return table?
function MatchTable:resultFromNonStandardRecord(record)
end

---@return {matches: WDLCount, games: WDLCount, rounds: WDLCount}
function MatchTable:statsFromMatches()
	local totalMatches = {w = 0, d = 0, l = 0}
	local totalGames = {w = 0, d = 0, l = 0}
	local totalRounds = {w = 0, d = 0, l = 0}

	local nonNegative = function(value)
		return math.max(tonumber(value) or 0, 0)
	end

	---@param opponent standardOpponent
	---@return boolean
	local hasWalkoverStatus = function(opponent)
		return Logic.isNotEmpty(opponent.status) and opponent.status ~= 'S'
	end

	Array.forEach(self.matches, function(match)
		if match.result.winner == DRAW_WINNER then
			totalMatches.d = totalMatches.d + 1
		elseif hasWalkoverStatus(match.result.opponent) or hasWalkoverStatus(match.result.vs) then
			return
		elseif match.result.winner == 1 then
			totalMatches.w = totalMatches.w + 1
		elseif match.result.winner == 2 then
			totalMatches.l = totalMatches.l + 1
		end

		if match.result.countGames then
			totalGames.w = totalGames.w + nonNegative(match.result.opponent.score)
			totalGames.l = totalGames.l + nonNegative(match.result.vs.score)
		end

		if match.result.countRounds then
			Array.forEach(match.result.gameOpponents, function (gameOpponent)
				totalRounds.w = totalRounds.w + nonNegative(gameOpponent.score)
			end)
			Array.forEach(match.result.gameVsOpponents, function (gameOpponent)
				totalRounds.l = totalRounds.l + nonNegative(gameOpponent.score)
			end)
		end
	end)

	return {
		matches = totalMatches,
		games = totalGames,
		rounds = totalRounds
	}
end

---@return Widget
function MatchTable:buildDisplay()
	return TableWidgets.Table{
		classes = {'match-table-wrapper'},
		sortable = self.config.sortableResults,
		columns = self:buildColumnDefinitions(),
		title = Logic.nilIfEmpty(self.config.title),
		children = WidgetUtil.collect(
			self:headerRow(),
			TableWidgets.TableBody{children = self:buildBody()}
		),
		footer = self:buildFooter()
	}
end

---@return Widget
function MatchTable:build()
	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		self:displayStats(),
		self:buildDisplay()
	)}
end

---@protected
---@return table[]
function MatchTable:buildColumnDefinitions()
	local config = self.config
	return WidgetUtil.collect(
		{
			-- Date column
			align = 'left',
			sortType = 'number',
		},
		config.showTier and {align = 'left'} or nil,
		config.showType and {align = 'center'} or nil,
		config.displayGameIcons and {align = 'center'} or nil,
		config.showIcon and {
			align = 'center',
			unsortable = true,
		} or nil,
		{
			-- Tournament column
			align = 'left',
		},
		config.showResult and WidgetUtil.collect(
			config.showOpponent and {align = 'center'} or nil,
			{
				-- Result indicator column
				align = 'center',
				width = '1.25rem',
			},
			{
				-- Score column
				align = 'center',
			},
			config.showOpponent and {
				-- Result indicator column
				align = 'center',
				width = '1.25rem',
			} or nil,
			{
				-- vs Opponent column
				align = 'left'
			}
		) or nil,
		config.showVod and {
			align = 'left',
			unsortable = true,
		} or nil,
		config.showMatchPage and {
			align = 'center',
			unsortable = true,
		} or nil
	)
end

---@param year number?
---@return Widget?
function MatchTable:_yearRow(year)
	if not year then return end
	return TableWidgets.Row{
		section = 'subhead',
		classes = {'sortbottom'},
		css = {['font-weight'] = 'bold'},
		children = TableWidgets.CellHeader{
			align = 'center',
			colspan = 100,
			children = year
		}
	}
end

---@return Html
function MatchTable:headerRow()
	---@param text string?
	---@return Widget
	local makeHeaderCell = function(text)
		return TableWidgets.CellHeader{children = text}
	end

	local config = self.config

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			makeHeaderCell('Date'),
			config.showTier and makeHeaderCell('Tier') or nil,
			config.showType and makeHeaderCell('Type') or nil,
			config.displayGameIcons and makeHeaderCell() or nil,
			config.showIcon and makeHeaderCell() or nil,
			makeHeaderCell('Tournament'),
			config.showResult and WidgetUtil.collect(
				config.showOpponent and makeHeaderCell(self.config.opponentHeader or 'Participant') or nil,
				TableWidgets.CellHeader{
					colspan = config.showOpponent and 3 or 2,
					children = 'Score'
				},
				TableWidgets.CellHeader{
					align = 'center',
					children = 'vs. Opponent'
				}
			) or nil,
			config.showVod and TableWidgets.CellHeader{
				align = 'center',
				children = 'VOD(s)'
			} or nil,
			config.showMatchPage and makeHeaderCell() or nil
		)}
	}}
end

---@return Widget[]
function MatchTable:buildBody()
	if Table.isEmpty(self.matches) then
		---@return string
		local function getNoResultText()
			local isH2H = Logic.isNotEmpty(self.config.vs)
			if isH2H then
				return I18n.translate(
					'matchtable-no-h2h-match-results',
					{
						mode = self.config.mode == Opponent.solo and 'players' or 'teams',
					}
				)
			end
			return I18n.translate(
				'matchtable-no-match-results',
				{
					mode = self.config.mode == Opponent.solo and 'player' or 'team',
				}
			)
		end

		return {TableWidgets.Row{
			css = {['font-style'] = 'italic'},
			children = TableWidgets.Cell{
				colspan = 100,
				children = getNoResultText(),
			}
		}}
	end

	return self:buildRows()
end

---@return Widget[]
function MatchTable:buildRows()
	---@type Widget[]
	local rows = {}

	local currentYear = math.huge
	Array.forEach(self.matches, function(match)
		local year = DateExt.getYearOf(match.date)
		if self.config.showYearHeaders and year ~= currentYear then
			currentYear = year
			table.insert(rows, self:_yearRow(year))
		end
		table.insert(rows, self:matchRow(match))
	end)

	return rows
end

---@return Widget?
function MatchTable:buildFooter()
	if not self.config.linkSubPage then
		return
	end
	return Link{
		link = self.title.text .. '/Matches',
		children = 'Extended list of matches'
	}
end

---@param match MatchTableMatch
---@return Widget
function MatchTable:matchRow(match)
	return TableWidgets.Row{
		highlighted = HighlightConditions.tournament(Tournament.partialTournamentFromMatch(match), self.args),
		children = WidgetUtil.collect(
			self:_displayDate(match),
			self:displayTier(match),
			self:_displayType(match),
			self:_displayGameIcon(match),
			self:_displayIcon(match),
			self:_displayTournament(match),
			self:_displayMatch(match),
			self:_displayVods(match),
			self:_displayMatchPage(match)
		)
	}
end

---@param match MatchTableMatch
---@return Widget
function MatchTable:_displayDate(match)
	return TableWidgets.Cell{
		attributes = {['data-sort-value'] = match.timestamp},
		children = not DateExt.isDefaultTimestamp(match.timestamp) and Countdown.create{
			finished = match.finished,
			date = DateExt.toCountdownArg(match.timestamp, match.timezoneId, match.dateIsExact),
			rawdatetime = true,
			format = self.config.dateFormat
		} or nil
	}
end

---@protected
---@param match MatchTableMatch
---@return Widget?
function MatchTable:displayTier(match)
	if not self.config.showTier then return end

	local tier, tierType, options = Tier.parseFromQueryData(match)
	options.link = true
	options.onlyTierTypeIfBoth = true

	if not Tier.isValid(tier, tierType) then
		return TableWidgets.Cell{
			attributes = {['data-sort-value'] = INVALID_TIER_SORT},
			children = INVALID_TIER_DISPLAY
		}
	end

	return TableWidgets.Cell{
		attributes = {['data-sort-value'] = Tier.toSortValue(tier, tierType)},
		children = Tier.display(tier, tierType, options)
	}
end

---@param match MatchTableMatch
---@return Widget?
function MatchTable:_displayType(match)
	if not self.config.showType then return end

	return TableWidgets.Cell{
		children = match.type and String.upperCaseFirst(match.type) or nil
	}
end

---@param match MatchTableMatch
---@return Widget?
function MatchTable:_displayGameIcon(match)
	if not self.config.displayGameIcons then return end

	return TableWidgets.Cell{
		children = Game.icon{game = match.game}
	}
end

---@param match MatchTableMatch
---@return Widget?
function MatchTable:_displayIcon(match)
	if not self.config.showIcon then return end

	return TableWidgets.Cell{
		children = LeagueIcon.display{
			icon = match.icon,
			iconDark = match.iconDark,
			link = match.pageName,
			name = match.displayName,
			options = {noTemplate = true},
		}
	}
end

---@param match MatchTableMatch
---@return Widget
function MatchTable:_displayTournament(match)
	return TableWidgets.Cell{
		children = Link{children = match.displayName, link = match.pageName}
	}
end

---@param match MatchTableMatch
---@return Widget|Widget[]?
function MatchTable:_displayMatch(match)
	if not self.config.showResult then
		return
	elseif Logic.isEmpty(match.result.vs) then
		return self:nonStandardMatch(match)
	end

	return WidgetUtil.collect(
		self.config.showOpponent and self:_displayOpponent(match.result.opponent, true) or nil,
		self:_displayScore(match),
		self:_displayOpponent(match.result.vs)
	)
end

---overwritable for wikis that have BR/FFA matches
---@param match MatchTableMatch
---@return Widget
function MatchTable:nonStandardMatch(match)
	return TableWidgets.Cell{
		colspan = self.config.showOpponent and 3 or 2,
		children = '',
	}
end

---@param opponent standardOpponent
---@param flipped boolean?
---@return Widget
function MatchTable:_displayOpponent(opponent, flipped)
	return TableWidgets.Cell{
		attributes = {['data-sort-value'] = Opponent.toName(opponent)},
		children = OpponentDisplay.BlockOpponent{
			opponent = opponent,
			flip = flipped,
			overflow = 'wrap',
			teamStyle = self.config.teamStyle,
		}
	}
end

---@param match MatchTableMatch
---@return Html
function MatchTable:_displayScore(match)
	local result = match.result
	local hasOnlyScores = Array.all({result.opponent, result.vs}, function(opponent)
		return opponent.status == 'S' end)
	local bestof1Score = match.bestof == 1 and Info.config.match2.gameScoresIfBo1 and hasOnlyScores

	---@param opponent standardOpponent
	---@param gameOpponents table[]
	---@return string|Widget
	local toScore = function(opponent, gameOpponents)
		if Table.isEmpty(opponent) or not opponent.status then return 'Unkn' end
		local score = OpponentDisplay.InlineScore(opponent)
		local status = opponent.status

		local game1Opponent = gameOpponents[1]
		if bestof1Score and game1Opponent then
			score = game1Opponent.score
			status = game1Opponent.status
		end

		return HtmlWidgets.Span{
			css = {['font-weight'] = tonumber(opponent.placement) == 1 and 'bold' or nil},
			children = status == SCORE_STATUS and (score or '&ndash;') or status,
		}
	end

	return {
		TableWidgets.Cell{children = MatchTable.getResultIndicator(match.result.winner)},
		TableWidgets.Cell{children = {
			toScore(result.opponent, result.gameOpponents),
			bestof1Score and BO1_SCORE_CONCAT or SCORE_CONCAT,
			toScore(result.vs, result.gameVsOpponents)
		}},
		self.config.showOpponent and TableWidgets.Cell{
			children = WinLossIndicator{
				opponentIndex = Array.indexOf(match.opponents, function (opponent)
					return Opponent.same(result.vs, opponent)
				end),
				winner = match.winner,
			}
		} or nil,
	}
end

---@param match MatchTableMatch
---@return Html?
function MatchTable:_displayVods(match)
	if not self.config.showVod then return end

	return TableWidgets.Cell{
		children = Array.interleave(Array.map(match.vods, function (vod)
			return VodLink.display{vod = vod.link, gamenum = vod.index ~= 0 and vod.index or nil}
		end), ' ')
	}
end

---@param match MatchTableMatch
---@return Html?
function MatchTable:_displayMatchPage(match)
	if not self.config.showMatchPage then return end

	return TableWidgets.Cell{
		children = MatchPageButton{match = match, buttonText = self.config.matchPageButtonText}
	}
end

---@protected
---@param winner integer
---@return Widget?
MatchTable.getResultIndicator = FnUtil.memoize(function (winner)
	return WinLossIndicator{
		opponentIndex = 1,
		winner = winner,
	}
end)

---@return Widget?
function MatchTable:displayStats()
	if not self.config.showStats or Table.isEmpty(self.matches) then return end

	local endTimeStamp = math.min(self.matches[1].timestamp, self.config.timeRange.endDate)
	local startTimeStamp = math.max(self.matches[#self.matches].timestamp, self.config.timeRange.startDate)

	---@param data {w: number, d: number, l: number}
	---@param statsType string
	---@return string?
	local displayScores = function(data, statsType)
		local sum = data.w + data.d + data.l
		if sum == 0 then return end

		local scoreText = table.concat(Array.extend(
			data.w .. 'W',
			data.d > 0 and (data.d .. 'D') or nil,
			data.l .. 'L'
		), ' : ')

		local percentage = Math.formatPercentage((data.w + 0.5 * data.d) / sum, 2)

		local parts = {
			scoreText,
			'(' .. percentage .. ')',
			'in',
			statsType,
		}

		return table.concat(parts, ' ')
	end

	local makeStatsTitle = function()
		if DateExt.isDefaultTimestamp(startTimeStamp) and DateExt.isDefaultTimestamp(endTimeStamp) then
			return 'For all matches:'
		elseif DateExt.isDefaultTimestamp(startTimeStamp) then
			return 'For all matches before '.. DateExt.formatTimestamp('M d, Y', endTimeStamp) .. ':'
		end

		local startDate = DateExt.formatTimestamp('M d, Y', startTimeStamp)
		local endDate = DateExt.formatTimestamp('M d, Y', endTimeStamp)
		return 'For matches between ' .. startDate .. ' and ' .. endDate .. ':'
	end

	local titleNode = HtmlWidgets.Div{
		css = {['font-weight'] = 'bold'},
		children = makeStatsTitle(),
	}

	local stats = Array.append({},
		self.config.showOnlyGameStats and '' or displayScores(self.stats.matches, 'matches'),
		displayScores(self.stats.games, 'games'),
		self.config.showOnlyGameStats and '' or displayScores(self.stats.rounds, 'rounds')
	)

	return HtmlWidgets.Div{children = {
		titleNode,
		HtmlWidgets.Div{children = Array.interleave(stats, self.config.showOnlyGameStats and '' or ' and ')}
	}}
end

return MatchTable

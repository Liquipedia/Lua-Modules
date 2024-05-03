---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local DateExt = require('Module:Date/Ext')
local Game = require('Module:Game')
local LeagueIcon = require('Module:LeagueIcon')
local Logic = require('Module:Logic')
local Lpdb = require('Module:Lpdb')
local Lua = require('Module:Lua')
local Math = require('Module:MathUtil')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Timezone = require('Module:Timezone')
local Team = require('Module:Team')
local Tier = require('Module:Tier/Custom')
local VodLink = require('Module:VodLink')

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

local UTC = 'UTC'
local DRAW = 'draw'
local RESULT_TYPE_DEFAULT = 'default'
local INVALID_TIER_DISPLAY = 'Undefined'
local INVALID_TIER_SORT = 'ZZ'
local SCORE_STATUS = 'S'
local SCORE_CONCAT = '&nbsp;&#58;&nbsp;'

---@alias MatchTableMode `Opponent.solo` | `Opponent.team`

---@class MatchTableConfig
---@field mode MatchTableMode
---@field limit number?
---@field displayGameIcons boolean
---@field showResult boolean
---@field aliases table<string, true>
---@field vs table<string, true>
---@field timeRange {startDate: number, endDate: number}
---@field title string?
---@field showTier boolean
---@field showIcon boolean
---@field showVod boolean
---@field showStats boolean
---@field showOpponent boolean
---@field queryHistoricalAliases boolean
---@field showType boolean
---@field showYearHeaders boolean

---@class MatchTableMatch
---@field timestamp number
---@field timezone string
---@field timeIsExact boolean
---@field liquipediatier string?
---@field liquipediatiertype string?
---@field displayName string
---@field icon string?
---@field iconDark string?
---@field pageName string
---@field vods {index: number, link: string}[]
---@field type string?
---@field result MatchTableMatchResult
---@field game string?
---@field date string

---@class MatchTableMatchResult
---@field opponent match2opponent
---@field vs match2opponent
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
function MatchTable:readConfig()
	local args = self.args

	local mode = args.tableMode
	assert(mode == Opponent.solo or mode == Opponent.team, 'Unsupported "|tableMode=" input')

	local opponents = self:_readOpponents(mode)

	self.config = {
		mode = mode,
		limit = tonumber(args.limit),
		displayGameIcons = Logic.readBool(args.gameIcons),
		showResult = Logic.nilOr(Logic.readBoolOrNil(args.showResult), true),
		timeRange = self:readTimeRange(),
		aliases = self:readAliases(mode),
		vs = {},
		title = args.title,
		showTier = not Logic.readBool(args.hide_tier),
		showIcon = not Logic.readBool(args.hide_icon),
		showVod = Logic.readBool(args.vod),
		showStats = Logic.nilOr(Logic.readBoolOrNil(args.stats), true),
		showOpponent = Logic.nilOr(Logic.readBoolOrNil(args.showOpponent), #opponents > 1 or mode == Opponent.solo),
		queryHistoricalAliases = not Logic.readBool(args.skipQueryingHistoricalAliases),
		showType = Logic.readBool(args.showType),
		showYearHeaders = Logic.readBool(args.showYearHeaders),
	}

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

---@param mode MatchTableMode
---@return standardOpponent[]
function MatchTable:_readOpponents(mode)
	local base = mode == Opponent.solo and 'player' or 'team'
	local inputs = self:_readOpponentInputsFromBase(base)

	if Logic.isEmpty(inputs) then
		assert(self.title.namespace == 0, 'Required ' .. base .. '= argument')
		table.insert(inputs, self.title.rootText)
	end

	return Array.map(inputs, function(input) return self:_readOpponent(mode, input) end)
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

	return Array.map(mw.text.split(self.args[base .. 's'], ',', true), String.trim)
end

---@param mode MatchTableMode
---@param input string
---@return standardOpponent
function MatchTable:_readOpponent(mode, input)
	if mode == Opponent.solo then
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

	local aliasInput = Array.map(mw.text.split(self.args.aliases, ','), String.trim)

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
	local opponentNames = self.config.queryHistoricalAliases and Team.queryHistoricalNames(opponent.template) or
		{opponent.template}

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
		endDate = yearRange[2] and DateExt.readTimestamp((yearRange[2] + 1) .. '-01-01') or DateExt.maxTimestamp,
	}
end

---@return self
function MatchTable:query()
	self.matches = {}

	Lpdb.executeMassQuery('match2', {
		conditions = self:buildConditions(),
		order = 'date desc',
		query = 'match2opponents, match2games, date, dateexact, icon, icondark, liquipediatier, game, type, '
			.. 'liquipediatiertype, tournament, pagename, vod, winner, walkover, resulttype, extradata',
	}, function(match)
		table.insert(self.matches, self:matchFromRecord(match) or nil)
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
		:add{self:buildAdditionalConditions()}
		:toString()
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
		conditions:add{ConditionNode(ColumnName('date'), Comparator.lt, DateExt.formatTimestamp('c', timeRange.endDate))}
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
	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('resulttype'), Comparator.neq, 'np')}
	local hasAdditionalConditions = false

	local getOrCondition = function(lpdbKey, input)
		if Logic.isEmpty(input) then return end

		hasAdditionalConditions = true
		local orConditions = ConditionTree(BooleanOperator.any)
		Array.forEach(mw.text.split(input, ','), function(value)
			orConditions:add{ConditionNode(ColumnName(lpdbKey), Comparator.eq, String.trim(value))}
		end)
		conditions:add(orConditions)
	end

	getOrCondition('liquipediatier', args.tier)
	getOrCondition('game', args.game)

	if Logic.isNotEmpty(args.bestof) then
		hasAdditionalConditions = true
		conditions:add(ConditionNode(ColumnName('bestof'), Comparator.eq, args.bestof))
	end

	if not hasAdditionalConditions then return end

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
		timestamp = record.extradata.timestamp,
		timezone = record.extradata.timezoneid or UTC,
		timeIsExact = Logic.readBool(record.dateexact),
		liquipediatier = record.liquipediatier,
		liquipediatiertype = record.liquipediatiertype,
		displayName = String.nilIfEmpty(record.tournament) or record.pagename:gsub('_', ' '),
		icon = String.nilIfEmpty(record.icon),
		iconDark = String.nilIfEmpty(record.icondark),
		pageName = record.pagename,
		vods = self:vodsFromRecord(record),
		type = record.type,
		result = result,
		game = record.game,
		date = record.date,
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
	if #record.match2opponents ~= 2 then
		return self:resultFromNonStandardRecord(record)
	end

	local aliases = self.config.aliases
	local countGames = false

	local foundInAlias = function(opponentRecord)
		if aliases[opponentRecord.name] then
			countGames = true
			return true
		end
		return self.config.mode == Opponent.solo and Array.any(opponentRecord.match2players, function(player)
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
		if match.result.resultType == RESULT_TYPE_DEFAULT then
			return
		elseif match.result.resultType == DRAW then
			totalMatches.d = totalMatches.d + 1
		elseif match.result.winner == 1 then
			totalMatches.w = totalMatches.w + 1
		elseif match.result.winner == 2 then
			totalMatches.l = totalMatches.l + 1
		end

		if match.result.countGames then
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
	local display = mw.html.create('table')
		:addClass('wikitable wikitable-striped sortable')
		:css('text-align', 'center')
		:node(self:_titleRow(self.config.title))
		:node(self:headerRow())

	if Table.isEmpty(self.matches) then
		local text = 'This ' .. (self.config.mode == Opponent.solo and Opponent.solo or Opponent.team)
			.. ' has not played any matches yet.'

		return mw.html.create('tr')
			:tag('td')
				:attr('colspan', '100')
				:css('font-style', 'italic')
				:wikitext(text)
				:done()
	end

	local currentYear
	Array.forEach(self.matches, function(match)
		local year = tonumber(match.date:sub(1, 4))
		if self.config.showYearHeaders and year ~= currentYear then
			currentYear = year
			display:node(self:_yearRow(year))
		end
		display:node(self:matchRow(match))
	end)

	local wrappedTableNode = mw.html.create('div')
		:addClass('match-table-wrapper')
		:addClass('table-responsive')
		:node(display)

	return mw.html.create('div')
		:node(self:displayStats())
		:node(wrappedTableNode)
end

---@param title string
---@return Html?
function MatchTable:_titleRow(title)
	if not title then return end
	return mw.html.create('tr')
		:tag('th')
			:attr('colspan', '100')
			:wikitext(title)
			:done()
end

---@param year number?
---@return Html?
function MatchTable:_yearRow(year)
	if not year then return end
	return mw.html.create('tr')
		:addClass('sortbottom')
		:tag('td')
			:attr('colspan', '100')
			:addClass('match-table-year-header')
			:wikitext(year)
			:done()
end

---@return Html
function MatchTable:headerRow()
	local makeHeaderCell = function(text, width)
		return mw.html.create('th'):css('max-width', width):node(text)
	end

	local config = self.config

	return mw.html.create('tr')
		:node(makeHeaderCell('Date', '100px'))
		:node(config.showTier and makeHeaderCell('Tier', '70px') or nil)
		:node(config.showType and makeHeaderCell('Type', '70px') or nil)
		:node(config.displayGameIcons and makeHeaderCell(nil, '25px') or nil)
		:node(config.showIcon and makeHeaderCell(nil, '25px'):addClass('unsortable') or nil)
		:node(makeHeaderCell('Tournament'))
		:node(config.showResult and config.showOpponent and makeHeaderCell('Participant', '120px') or nil)
		:node(config.showResult and makeHeaderCell('Score', '68px'):addClass('unsortable') or nil)
		:node(config.showResult and makeHeaderCell('vs. Opponent', '120px') or nil)
		:node(config.showVod and makeHeaderCell('VOD(s)', '80px'):addClass('unsortable') or nil)
end

---@param match MatchTableMatch
---@return Html?
function MatchTable:matchRow(match)
	return mw.html.create('tr')
		:addClass(self:_getBackgroundClass(match.result.winner))
		:node(self:_displayDate(match))
		:node(self:_displayTier(match))
		:node(self:_displayType(match))
		:node(self:_displayGameIcon(match))
		:node(self:_displayIcon(match))
		:node(self:_displayTournament(match))
		:node(self:_displayMatch(match))
		:node(self:_displayVods(match))
end

---@param match MatchTableMatch
---@return Html
function MatchTable:_displayDate(match)
	local cell = mw.html.create('td')
		:css('text-align', 'left')
		:attr('data-sort-value', match.timestamp)

	if match.timestamp == DateExt.defaultTimestamp then
		return cell
	end

	if not match.timeIsExact then
		return cell:node(DateExt.formatTimestamp('M d, Y', match.timestamp))
	end

	return cell:node(Countdown._create{
		timestamp = match.timestamp,
		finished = true,
		date = MatchTable._calculateDateTimeString(match.timezone, match.timestamp),
		rawdatetime = true,
	} or nil)
end

---@param timezone string
---@param timestamp number
---@return string
function MatchTable._calculateDateTimeString(timezone, timestamp)
	local offset = Timezone.getOffset(timezone) or 0

	return DateExt.formatTimestamp('M d, Y - H:i', timestamp + offset) ..
		' ' .. Timezone.getTimezoneString(timezone)
end

---@param match MatchTableMatch
---@return Html?
function MatchTable:_displayTier(match)
	if not self.config.showTier then return end

	local tier, tierType, options = Tier.parseFromQueryData(match)
	options.link = true
	options.onlyTierTypeIfBoth = true

	if not Tier.isValid(tier, tierType) then
		return mw.html.create('td')
			:attr('data-sort-value', INVALID_TIER_DISPLAY)
			:wikitext(INVALID_TIER_SORT)
	end

	return mw.html.create('td')
		:attr('data-sort-value', Tier.toSortValue(tier, tierType))
		:wikitext(Tier.display(tier, tierType, options))
end

---@param match MatchTableMatch
---@return Html?
function MatchTable:_displayType(match)
	if not self.config.showType then return end

	return mw.html.create('td')
		:wikitext(match.type and mw.getContentLanguage():ucfirst(match.type) or nil)
end

---@param match MatchTableMatch
---@return Html?
function MatchTable:_displayGameIcon(match)
	if not self.config.displayGameIcons then return end

	return mw.html.create('td')
		:node(Game.icon{game = match.game})
end

---@param match MatchTableMatch
---@return Html?
function MatchTable:_displayIcon(match)
	if not self.config.showIcon then return end

	return mw.html.create('td')
		:node(LeagueIcon.display{
			icon = match.icon,
			iconDark = match.iconDark,
			link = match.pageName,
			name = match.displayName,
			options = {noTemplate = true},
		})
end

---@param match MatchTableMatch
---@return Html
function MatchTable:_displayTournament(match)
	return mw.html.create('td')
		:css('text-align', 'left')
		:wikitext(Page.makeInternalLink(match.displayName, match.pageName))
end

---@param match MatchTableMatch
---@return Html?
function MatchTable:_displayMatch(match)
	if not self.config.showResult then
		return
	elseif Logic.isEmpty(match.result.vs) then
		return self:nonStandardMatch(match)
	end

	return mw.html.create()
		:node(self.config.showOpponent and self:_displayOpponent(match.result.opponent, true) or nil)
		:node(self:_displayScore(match.result))
		:node(self:_displayOpponent(match.result.vs):css('text-align', 'left'))
end

---overwritable for wikis that have BR/FFA matches
---@param match MatchTableMatch
---@return Html
function MatchTable:nonStandardMatch(match)
	return mw.html.create('td')
		:attr('colspan', self.config.showOpponent and 3 or 2)
		:wikitext('')
end

---@param opponentRecord match2opponent
---@param flipped boolean?
---@return Html
function MatchTable:_displayOpponent(opponentRecord, flipped)
	local cell = mw.html.create('td')
	local opponent = Opponent.fromMatch2Record(opponentRecord)
	if Logic.isEmpty(opponent) then return cell:wikitext('Unknown') end

	return cell
		:node(OpponentDisplay.BlockOpponent{
			opponent = opponent,
			flip = flipped,
			overflow = 'wrap',
			teamStyle = 'short',
		})
		:attr('data-sort-value', opponent.name)
end

---@param result MatchTableMatchResult
---@return Html
function MatchTable:_displayScore(result)
	---@param opponentRecord match2opponent
	---@return unknown
	local toScore = function(opponentRecord)
		if Table.isEmpty(opponentRecord) or not opponentRecord.status then return 'Unkn' end
		return mw.html.create(tonumber(opponentRecord.placement) == 1 and 'b' or nil)
			:wikitext(opponentRecord.status == SCORE_STATUS and (opponentRecord.score or '–') or opponentRecord.status)
	end

	return mw.html.create('td')
		:addClass('match-table-score')
		:node(toScore(result.opponent))
		:node(SCORE_CONCAT)
		:node(toScore(result.vs))
end

---@param match MatchTableMatch
---@return Html?
function MatchTable:_displayVods(match)
	if not self.config.showVod then return end

	local vodsNode = mw.html.create('td'):css('text-align', 'left')
	Array.forEach(match.vods, function(vod, vodIndex)
		if vodIndex ~= 1 then
			vodsNode:node(' ')
		end
		vodsNode:node(VodLink.display{vod = vod.link, gamenum = vod.index ~= 0 and vod.index or nil})
	end)

	return vodsNode
end

---@param winner any
---@return string?
function MatchTable:_getBackgroundClass(winner)
	return winner == 1 and 'recent-matches-bg-win' or
		winner == 0 and 'recent-matches-bg-tie' or
		winner == 2 and 'recent-matches-bg-lose' or
		nil
end

---@return Html?
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

		local percentage = Math.round((data.w + 0.5 * data.d) / sum, 4) * 100

		local parts = {
			scoreText,
			'(' .. percentage .. '%)',
			'in',
			statsType,
		}

		return table.concat(parts, ' ')
	end

	local startDate = DateExt.formatTimestamp('M d, Y', startTimeStamp)
	local endDate = DateExt.formatTimestamp('M d, Y', endTimeStamp)
	local titleText = 'For matches between ' .. startDate .. ' and ' .. endDate .. ':'

	local titleNode = mw.html.create('div')
		:css('font-weight', 'bold')
		:wikitext(titleText)

	local stats = Array.append({},
		displayScores(self.stats.matches, 'matches'),
		displayScores(self.stats.games, 'games')
	)

	return mw.html.create('div')
		:node(titleNode)
		:tag('div')
			:wikitext(table.concat(stats, ' and '))
			:wikitext()
			:done()
end

return MatchTable

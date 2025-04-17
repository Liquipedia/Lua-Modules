---
-- @Liquipedia
-- wiki=commons
-- page=Module:MatchesScheduleDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local Class = require('Module:Class')
local Countdown = require('Module:Countdown')
local DateExt = require('Module:Date/Ext')
local HiddenSort = require('Module:HiddenSort')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local UTC = ' <abbr data-tz="+0:00" title="Coordinated Universal Time (UTC)">UTC</abbr>'
local WINNER_LEFT = 1
local WINNER_RIGHT = 2
local SCORE_STATUS = 'S'
local DO_FLIP = true
local NO_FLIP = false
local LEFT_SIDE_OPPONENT = 'Left'
local RIGHT_SIDE_OPPONENT = 'Right'
local DEFAULT_QUERY_LIMIT = 1000

-- If run in abbreviated roundnames mode
local ABBREVIATIONS = {
	["Upper Bracket"] = "UB",
	["Lower Bracket"] = "LB",
}

---@class MatchesTable
---@operator call(table<string, any>): MatchesTable
---@field args table<string, any>
---@field config table<string, boolean|string|number|string[]>
---@field currentId string?
---@field currentMatchHeader string[]?
local MatchesTable = Class.new(function(self, args) self:init(args) end)

---@param args table?
---@return MatchesTable
function MatchesTable:init(args)
	args = args or {}
	self.args = args

	args.tournament = args.tournament or mw.title.getCurrentTitle().prefixedText

	self.config = {
		limit = tonumber(args.limit) or DEFAULT_QUERY_LIMIT,
		startDate = args.sdate,
		endDate = args.edate,
		section = args.section,
		matchSection = args.matchsection,
		showRound = not Logic.readBool(args.hideround),
		sortRound = Logic.readBool(args.sortround),
		showCountdown = Logic.readBool(args.countdown),
		showMatchPage = Logic.readBool(args.matchpage),
		onlyShowExactDates = Logic.readBool(args.dateexact),
		shortenRoundNames = Logic.readBool(args.shortedroundnames),
		pages = Array.map(Array.extractValues(
				Table.filterByKey(args, function(key) return key:find('^tournament%d-$') end)
			), function(page) return (page:gsub(' ', '_')) end),
	}

	return self
end

---@return Html?
function MatchesTable:create()
	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		limit = self.config.limit,
		order = 'date asc',
		conditions = self:buildConditions(),
	})

	if type(matches[1]) ~= 'table' then
		return
	end
	self.matches = matches

	local output = mw.html.create('table')
		:addClass('wikitable wikitable-striped sortable match-card')
		:node(self:header())

	Array.forEach(self.matches, function(match, matchIndex) output:node(self:row(match)) end)

	return mw.html.create('div')
		:addClass('table-responsive')
		:css('margin-bottom', '10px')
		:node(output)
end

---@return string
function MatchesTable:buildConditions()
	local config = self.config

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('date'), Comparator.gt, DateExt.defaultDate)}

	local pageConditions = ConditionTree(BooleanOperator.any)
	for _, page in pairs(config.pages --[[@as string[] ]]) do
		pageConditions:add{ConditionNode(ColumnName('pagename'), Comparator.eq, page)}
	end
	conditions:add(pageConditions)

	if config.startDate then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('date'), Comparator.eq, config.startDate),
			ConditionNode(ColumnName('date'), Comparator.gt, config.startDate),
		})
	end

	if config.endDate then
		conditions:add(ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName('date'), Comparator.eq, config.endDate),
			ConditionNode(ColumnName('date'), Comparator.lt, config.endDate),
		})
	end

	if config.matchSection then
		conditions:add{ConditionNode(ColumnName('extradata_matchsection'), Comparator.eq, config.matchSection)}
	end

	if config.section then
		conditions:add{ConditionNode(ColumnName('match2bracketdata_sectionheader'), Comparator.eq, config.section)}
	end

	return conditions:toString()
end

---@return Html
function MatchesTable:header()
	local header = mw.html.create('tr')
		:addClass('HeaderRow')
		:node(mw.html.create('th')
			:addClass('divCell')
			:attr('data-sort-type','isoDate')
			:wikitext('Date')
		)

	if self.config.showRound then
		header:tag('th')
			:addClass('divCell')
			:addClass(not self.config.sortRound and 'unsortable' or nil)
			:wikitext('Round')
	end

	return header
		:tag('th'):addClass('divCell'):wikitext('Opponent'):done()
		:tag('th'):addClass('divCell'):css('width','50'):wikitext('Score'):done()
		:tag('th'):addClass('divCell'):wikitext('vs. Opponent'):done()
		:node(self.config.showMatchPage and mw.html.create('th'):addClass('divCell') or nil)
end

---@param match table
---@return Html
function MatchesTable:dateDisplay(match)
	local dateCell = mw.html.create('td')
		:addClass('Date')
		:node(HiddenSort.run(match.date))

	if Logic.readBool(match.dateexact) then
		local countdownArgs = {}
		if self.config.showCountdown and not Logic.readBool(match.finished) then
			countdownArgs = match.stream or {}
			countdownArgs.rawcountdown = true
		else
			countdownArgs.rawdatetime = true
		end
		countdownArgs.date = match.date .. UTC
		return dateCell:wikitext(Countdown._create(countdownArgs))
	elseif self.config.onlyShowExactDates then
		return dateCell
			:css('text-align', 'center')
			:css('font-style', 'italic')
			:wikitext('To be announced')
	end

	return dateCell:wikitext(mw.getContentLanguage():formatDate('F j, Y', match.date))
end

---@param match table
---@return Html
function MatchesTable:row(match)
	local matchHeader = self:determineMatchHeader(match)

	local row = mw.html.create('tr')
		:addClass('Match')
		:node(self:dateDisplay(match))

	if self.config.showRound then
		row:tag('td'):addClass('Round'):wikitext(matchHeader)
	end

	return row
		:node(MatchesTable._buildOpponent(match.match2opponents[1], DO_FLIP, LEFT_SIDE_OPPONENT))
		:node(MatchesTable.score(match))
		:node(MatchesTable._buildOpponent(match.match2opponents[2], NO_FLIP, RIGHT_SIDE_OPPONENT))
		:node(self.config.showMatchPage and MatchesTable.matchPageLinkDisplay(match) or nil)
end

---@param match table
---@return string
function MatchesTable:determineMatchHeader(match)
	local matchHeader = Logic.emptyOr(
		match.match2bracketdata.inheritedheader or match.extradata.matchsection,
		self.currentId == match.match2bracketid and self.currentMatchHeader or nil,
		--if we do not have a matchHeader yet try:
		-- 1) the title (in case it is a matchlist)
		-- 2) the sectionheader
		-- 3) fallback to the previous _matchHeader
		-- last one only applies if we are in a new matchGroup due to it already being used before else
		Logic.emptyOr(
			string.gsub(match.match2bracketdata.title or '', '%s[mM]atches', ''),
			match.match2bracketdata.sectionheader,
			self.currentMatchHeader or '&nbsp;'
	))

	--if the header is a default bracket header we need to convert it to proper display text
	local headerArray
	if type(matchHeader) == 'string' then
		headerArray = DisplayHelper.expandHeader(matchHeader)
	else
		headerArray = matchHeader or {}
	end

	self.currentId = match.match2bracketid
	self.currentMatchHeader = headerArray

	if self.config.shortenRoundNames then
		return headerArray[3] or MatchesTable._applyCustomAbbreviations(headerArray[1])
	end

	return headerArray[1]
end

---@param matchHeader string
---@return string
function MatchesTable._applyCustomAbbreviations(matchHeader)
	for long, short in pairs(ABBREVIATIONS) do
		matchHeader = matchHeader:gsub(long, short)
	end

	return matchHeader
end

---@param opponent table
---@param flip boolean
---@param side string
---@return Html
function MatchesTable._buildOpponent(opponent, flip, side)
	local opponentCell = mw.html.create('td'):addClass('Team' .. side)

	opponent = Opponent.fromMatch2Record(opponent) --[[@as standardOpponent]]

	if Opponent.isTbd(opponent) or Opponent.isEmpty(opponent) then
		opponent = Opponent.tbd(Opponent.literal)
	end

	return opponentCell:node(OpponentDisplay.InlineOpponent{
		opponent = opponent,
		teamStyle = 'short',
		flip = flip,
		abbreviateTbd = true,
	})
end

---@param match table
---@return Html
function MatchesTable.score(match)
	local scoreCell = mw.html.create('td')
		:addClass('Score')

	local scoreDisplay = (Logic.readBool(match.finished) or (
		Logic.readBool(match.dateexact) and
		os.time() >= MatchesTable._parseDateTime(match.date)
	)) and MatchesTable.scoreDisplay(match) or 'vs'

	if (tonumber(match.bestof) or 0) <= 0 then
		return scoreCell:wikitext(scoreDisplay)
	end

	return scoreCell
		:tag('div'):css('line-height', '1.1'):node(scoreDisplay):done()
		:tag('div')
			:css('font-size', '75%')
			:css('padding-bottom', '1px')
			:wikitext('(')
			:node(MatchesTable._bestof(match.bestof))
			:wikitext(')')
			:done()
end

---@param match table
---@return string
function MatchesTable.scoreDisplay(match)
	return MatchesTable.getOpponentScore(
		match.match2opponents[1],
		match.winner == WINNER_LEFT
	) .. ':' .. MatchesTable.getOpponentScore(
		match.match2opponents[2],
		match.winner == WINNER_RIGHT
	)
end

---@param match table
---@return Html
function MatchesTable.matchPageLinkDisplay(match)
	return mw.html.create('td'):addClass('MatchPage')
		:wikitext('[[Match:ID_' .. match.match2id .. '|')
		:tag('span')
			:addClass('fa-stack')
			:tag('i')
				:addClass('fad fa-file fa-stack-2x')
				:done()
			:tag('i')
				:addClass('fas fa-info fa-stack-1x')
				:done()
			:done()
		:wikitext('Match Page')
		:wikitext(']]')
end

---@param opponent match2opponent
---@param isWinner boolean
---@return string|number?
function MatchesTable.getOpponentScore(opponent, isWinner)
	local score
	if opponent.status == SCORE_STATUS then
		score = tonumber(opponent.score)
		score = score == -1 and 0 or score
	else
		score = opponent.status or ''
	end
	if isWinner then
		return '<b>' .. score .. '</b>'
	end

	return score
end

---@param str string
---@return integer
function MatchesTable._parseDateTime(str)
	local year, month, day, hour, minutes, seconds
		= str:match('(%d%d%d%d)-?(%d?%d?)-?(%d?%d?) (%d?%d?):(%d?%d?):(%d?%d?)$')

	-- Adjust time based on server timezone offset from UTC
	local offset = os.time(os.date("*t") --[[@as osdateparam]]) - os.time(os.date("!*t") --[[@as osdateparam]])
	-- create time - this will take our UTC timestamp and put it into localtime without converting
	local localTime = os.time{
		year = year,
		month = month,
		day = day,
		hour = hour,
		min = minutes,
		sec = seconds
	}

	return localTime + offset -- "Convert" back to UTC
end

---@param value string|number
---@return string
function MatchesTable._bestof(value)
	return Abbreviation.make{text = 'Bo' .. value, title = 'Best of ' .. value} --[[@as string]]
end

return MatchesTable

---
-- @Liquipedia
-- page=Module:MatchesScheduleDisplay
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info', {loadData = true})
local HiddenSort = Lua.import('Module:HiddenSort')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local Td = HtmlWidgets.Td
local Th = HtmlWidgets.Th
local Tr = HtmlWidgets.Tr
local DataTable = Lua.import('Module:Widget/Basic/DataTable')
local MatchPageButton = Lua.import('Module:Widget/Match/PageButton')
local WidgetUtil = Lua.import('Module:Widget/Util')

local WINNER_LEFT = 1
local WINNER_RIGHT = 2
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
		showMatchPage = Info.config.match2.matchPage,
		onlyShowExactDates = Logic.readBool(args.dateexact),
		shortenRoundNames = Logic.readBool(args.shortedroundnames),
		pages = Array.map(Array.extractValues(
				Table.filterByKey(args, function(key) return string.find(key, '^tournament%d-$') ~= nil end)
			), function(page) return (page:gsub(' ', '_')) end),
	}

	return self
end

---@return Widget?
function MatchesTable:create()
	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		limit = self.config.limit,
		order = 'date asc',
		conditions = tostring(self:buildConditions()),
	})

	if type(matches[1]) ~= 'table' then
		return
	end
	self.matches = matches

	return DataTable{
		css = {['margin-bottom'] = '10px'},
		classes = {'wikitable-striped', 'match-card'},
		sortable = true,
		children = WidgetUtil.collect(
			self:header(),
			Array.map(self.matches, function (match) return self:row(match) end)
		)
	}
end

---@return ConditionTree
function MatchesTable:buildConditions()
	local config = self.config

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.gt, DateExt.defaultDate),
		ConditionUtil.anyOf(ColumnName('pagename'), config.pages --[[ @as string[] ]]),
	}

	if config.startDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.ge, config.startDate))
	end

	if config.endDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.le, config.endDate))
	end

	if config.matchSection then
		conditions:add{ConditionNode(ColumnName('extradata_matchsection'), Comparator.eq, config.matchSection)}
	end

	if config.section then
		conditions:add{ConditionNode(ColumnName('match2bracketdata_sectionheader'), Comparator.eq, config.section)}
	end

	return conditions
end

---@return Widget
function MatchesTable:header()
	return Tr{
		classes = {'HeaderRow'},
		children = WidgetUtil.collect(
			Th{
				classes = {'divCell'},
				attributes = {['data-sort-type'] = 'isoDate'},
				children = 'Date'
			},
			self.config.showRound and Th{
				classes = {'divCell', not self.config.sortRound and 'unsortable' or nil},
				children = 'Round'
			} or nil,
			Th{
				classes = {'divCell'},
				children = 'Opponent'
			},
			Th{
				classes = {'divCell'},
				css = {width = 50},
				children = 'Score'
			},
			Th{
				classes = {'divCell'},
				children = 'vs. Opponent'
			},
			self.config.showMatchPage and Th{
				classes = {'divCell', 'unsortable'}
			} or nil
		)
	}
end

---@param match MatchGroupUtilMatch
---@return Widget
function MatchesTable:dateDisplay(match)
	---@param props {css: table<string, string|number|nil>, children: string|Widget|(string|Widget)[]}
	---@return Widget
	local function createDateCell(props)
		return Td{
			classes = {'Date'},
			css = props.css,
			children = WidgetUtil.collect(
				HiddenSort.run(match.date),
				props.children
			)
		}
	end

	if Logic.readBool(match.dateIsExact) then
		local countdownArgs = {}
		if self.config.showCountdown and not Logic.readBool(match.finished) then
			countdownArgs = match.stream or {}
			countdownArgs.rawcountdown = true
		else
			countdownArgs.rawdatetime = true
		end
		countdownArgs.timestamp = match.timestamp
		countdownArgs.date = DateExt.toCountdownArg(match.timestamp, match.timezoneId)
		return createDateCell{children = Countdown.create(countdownArgs)}
	elseif self.config.onlyShowExactDates then
		return createDateCell{
			css = {
				['text-align'] = 'center',
				['font-style'] = 'italic'
			},
			children = 'To be announced'
		}
	end

	return createDateCell{children = DateExt.formatTimestamp('F j, Y', match.timestamp)}
end

---@param record match2
---@return Widget
function MatchesTable:row(record)
	local matchHeader = self:determineMatchHeader(record)

	local match = MatchGroupUtil.matchFromRecord(record)

	return Tr{
		classes = {'Match'},
		children = WidgetUtil.collect(
			self:dateDisplay(match),
			self.config.showRound and Td{
				classes = {'Round'},
				children = matchHeader
			} or nil,
			MatchesTable._buildOpponent(match.opponents[1], DO_FLIP, LEFT_SIDE_OPPONENT),
			MatchesTable.score(match),
			MatchesTable._buildOpponent(match.opponents[2], NO_FLIP, RIGHT_SIDE_OPPONENT),
			self.config.showMatchPage and MatchesTable.matchPageLinkDisplay(match) or nil
		)
	}
end

---@param match match2
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

---@param opponent standardOpponent
---@param flip boolean
---@param side string
---@return Widget
function MatchesTable._buildOpponent(opponent, flip, side)
	if Opponent.isTbd(opponent) or Opponent.isEmpty(opponent) then
		opponent = Opponent.tbd(Opponent.literal)
	end

	return Td{
		classes = {'Team' .. side},
		children = OpponentDisplay.InlineOpponent{
			opponent = opponent,
			teamStyle = 'short',
			flip = flip,
		}
	}
end

---@param match MatchGroupUtilMatch
---@return Widget
function MatchesTable.score(match)
	local scoreDisplay = (match.finished or (
		match.dateIsExact and
		DateExt.getCurrentTimestamp() >= match.timestamp
	)) and MatchesTable.scoreDisplay(match) or 'vs'

	local showBestOf = (tonumber(match.bestof) or 0) > 0

	return Td{
		classes = {'Score'},
		children = WidgetUtil.collect(
			showBestOf and {
				Div{
					css = {['line-height'] = '1.1'},
					children = scoreDisplay
				},
				Div{
					css = {
						['font-size'] = '75%',
						['padding-bottom'] = '1px'
					},
					children = {
						'(',
						MatchesTable._bestof(match.bestof),
						')'
					}
				}
			} or scoreDisplay
		)
	}
end

---@param match MatchGroupUtilMatch
---@return (string|Widget)[]
function MatchesTable.scoreDisplay(match)
	return {
		MatchesTable.getOpponentScore(
			match.opponents[1],
			match.winner == WINNER_LEFT
		),
		':',
		MatchesTable.getOpponentScore(
			match.opponents[2],
			match.winner == WINNER_RIGHT
		)
	}
end

---@param match MatchGroupUtilMatch
---@return Widget
function MatchesTable.matchPageLinkDisplay(match)
	return Td{
		classes = {'MatchPage'},
		children = MatchPageButton{match = match}
	}
end

---@param opponent standardOpponent
---@param isWinner boolean
---@return string|Widget
function MatchesTable.getOpponentScore(opponent, isWinner)
	local score = OpponentDisplay.InlineScore(opponent)
	if isWinner then
		return HtmlWidgets.B{children = score}
	end

	return score
end

---@param value string|number
---@return Widget
function MatchesTable._bestof(value)
	return HtmlWidgets.Abbr{
		title = 'Best of ' .. value,
		children = 'Bo' .. value
	}
end

return MatchesTable

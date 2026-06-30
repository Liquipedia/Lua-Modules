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
local Logic = Lua.import('Module:Logic')
local TournamentStructure = Lua.import('Module:TournamentStructure')

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

local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local MatchPageButton = Lua.import('Module:Widget/Match/PageButton')
local WidgetUtil = Lua.import('Module:Widget/Util')

local WINNER_LEFT = 1
local WINNER_RIGHT = 2
local DO_FLIP = true
local NO_FLIP = false
local DEFAULT_QUERY_LIMIT = 1000

-- If run in abbreviated roundnames mode
local ABBREVIATIONS = {
	["Upper Bracket"] = "UB",
	["Lower Bracket"] = "LB",
}

---@class MatchesTableConfig
---@field limit integer
---@field startDate string?
---@field endDate string?
---@field showRound boolean
---@field sortRound boolean
---@field showCountdown boolean
---@field showMatchPage boolean
---@field onlyShowExactDates boolean
---@field shortenRoundNames boolean
---@field matchGroupsSpec MatchGroupsSpec

---@class MatchesTable
---@operator call(table<string, any>): MatchesTable
---@field args table<string, any>
---@field config MatchesTableConfig
---@field currentId string?
---@field currentMatchHeader string[]?
local MatchesTable = Class.new(function(self, args) self:init(args) end)

---@param args table?
---@return MatchesTable
function MatchesTable:init(args)
	args = args or {}
	self.args = args

	self.config = {
		limit = tonumber(args.limit) or DEFAULT_QUERY_LIMIT,
		startDate = args.sdate,
		endDate = args.edate,
		showRound = not Logic.readBool(args.hideround),
		sortRound = Logic.readBool(args.sortround),
		showCountdown = Logic.readBool(args.countdown),
		showMatchPage = Info.config.match2.matchPage,
		onlyShowExactDates = Logic.readBool(args.dateexact),
		shortenRoundNames = Logic.readBool(args.shortedroundnames),
		matchGroupsSpec = TournamentStructure.readMatchGroupsSpec(args) or TournamentStructure.currentPageSpec(),
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

	return TableWidgets.Table{
		sortable = true,
		columns = WidgetUtil.collect(
			{
				align = 'left',
				sortType = 'isoDate',
			},
			self.config.showRound and {align = 'left'} or nil,
			{align = 'right'},
			{align = 'center'},
			{align = 'left'},
			self.config.showMatchPage and {
				unsortable = true,
				align = 'center'
			} or nil
		),
		children = {
			TableWidgets.TableHeader{children = self:header()},
			TableWidgets.TableBody{
				children = Array.map(self.matches, function (match) return self:row(match) end)
			}
		}
	}
end

---@return ConditionTree
function MatchesTable:buildConditions()
	local config = self.config

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('date'), Comparator.gt, DateExt.defaultDate),
		TournamentStructure.getMatch2Filter(config.matchGroupsSpec),
	}

	if config.startDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.ge, config.startDate))
	end

	if config.endDate then
		conditions:add(ConditionNode(ColumnName('date'), Comparator.le, config.endDate))
	end

	return conditions
end

---@return VNode
function MatchesTable:header()
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.CellHeader{
				children = 'Date'
			},
			self.config.showRound and TableWidgets.CellHeader{
				children = 'Round'
			} or nil,
			TableWidgets.CellHeader{
				children = 'Opponent'
			},
			TableWidgets.CellHeader{
				children = 'Score'
			},
			TableWidgets.CellHeader{
				children = 'vs. Opponent'
			},
			self.config.showMatchPage and TableWidgets.CellHeader{} or nil
		)
	}
end

---@param match MatchGroupUtilMatch
---@return VNode
function MatchesTable:dateDisplay(match)
	---@param props {css: table<string, string|number?>?, children: Renderable|Renderable[]}
	---@return VNode
	local function createDateCell(props)
		return TableWidgets.Cell{
			css = props.css,
			attributes = {['data-sort-value'] = match.date},
			children = props.children
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
---@return VNode
function MatchesTable:row(record)
	local matchHeader = self:determineMatchHeader(record)

	local match = MatchGroupUtil.matchFromRecord(record)

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			self:dateDisplay(match),
			self.config.showRound and TableWidgets.Cell{
				children = matchHeader
			} or nil,
			MatchesTable._buildOpponent(match.opponents[1], DO_FLIP),
			MatchesTable.score(match),
			MatchesTable._buildOpponent(match.opponents[2], NO_FLIP),
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
---@return VNode
function MatchesTable._buildOpponent(opponent, flip)
	if Opponent.isTbd(opponent) or Opponent.isEmpty(opponent) then
		opponent = Opponent.tbd(Opponent.literal)
	end

	return TableWidgets.Cell{
		children = OpponentDisplay.BlockOpponent{
			opponent = opponent,
			teamStyle = 'hybrid',
			flip = flip,
		}
	}
end

---@param match MatchGroupUtilMatch
---@return VNode
function MatchesTable.score(match)
	local scoreDisplay = (match.finished or (
		match.dateIsExact and
		DateExt.getCurrentTimestamp() >= match.timestamp
	)) and MatchesTable.scoreDisplay(match) or 'vs'

	local showBestOf = (tonumber(match.bestof) or 0) > 0

	return TableWidgets.Cell{
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
---@return Renderable[]
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
---@return VNode
function MatchesTable.matchPageLinkDisplay(match)
	return TableWidgets.Cell{children = MatchPageButton{match = match}}
end

---@param opponent standardOpponent
---@param isWinner boolean
---@return Renderable
function MatchesTable.getOpponentScore(opponent, isWinner)
	local score = OpponentDisplay.InlineScore(opponent)
	if isWinner then
		return Html.B{children = score}
	end

	return score
end

---@param value string|number
---@return VNode
function MatchesTable._bestof(value)
	return Html.Abbr{
		title = 'Best of ' .. value,
		children = 'Bo' .. value
	}
end

return MatchesTable

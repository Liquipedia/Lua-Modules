---
-- @Liquipedia
-- page=Module:StreamPage/Base
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Image = Lua.import('Module:Image')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local MatchPage = Lua.requireIfExists('Module:MatchPage')
local MatchTable = Lua.import('Module:MatchTable')
local MatchTicker = Lua.import('Module:MatchTicker')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Page = Lua.import('Module:Page')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Tournament = Lua.import('Module:Tournament')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local GridWidgets = Lua.import('Module:Widget/Grid')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local MatchPageAdditionalSection = Lua.import('Module:Widget/Match/Page/AdditionalSection')
local MatchPageHeader = Lua.import('Module:Widget/Match/Page/Header')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class BaseStreamPage: BaseClass
---@operator call(table): BaseStreamPage
---@field channel string
---@field provider string
---@field matches MatchGroupUtilMatch[]
local StreamPage = Class.new(function (self, args)
	self.channel = assert(Logic.nilIfEmpty(args.channel))
	self.provider = assert(Logic.nilIfEmpty(args.provider))
	self.matches = {}

	self:_fetchMatches()
end)


function StreamPage.run(frame)
	local args = Arguments.getArgs(frame)
	return StreamPage(args):create()
end

---@private
---@return ConditionTree
function StreamPage:_createMatchQueryCondition()
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionTree(BooleanOperator.any):add{
			ConditionNode(ColumnName(self.provider, 'stream'), Comparator.eq, self.channel),
			ConditionNode(ColumnName(self.provider .. '_en_1', 'stream'), Comparator.eq, self.channel)
		},
		ConditionNode(ColumnName('finished'), Comparator.eq, 0),
		ConditionNode(ColumnName('date'), Comparator.neq, DateExt.defaultDateTime),
		ConditionNode(ColumnName('dateexact'), Comparator.eq, 1)
	}

	conditions:add(StreamPage:addMatchConditions())
	return conditions
end

---@private
function StreamPage:_fetchMatches()
	local conditions = self:_createMatchQueryCondition()

	Lpdb.executeMassQuery('match2', {
		conditions = tostring(conditions),
		order = 'date asc',
		limit = 25,
	}, function (record)
		local match = MatchGroupUtil.matchFromRecord(record)
		if Array.any(match.opponents, Opponent.isBye) then
			return
		elseif #self.matches == 5 then
			return false
		end
		Array.appendWith(self.matches, match)
	end)
end

---@protected
---@return AbstractConditionNode|AbstractConditionNode[]?
function StreamPage:addMatchConditions()
end

---@private
---@return Widget
function StreamPage:_header()
	local match = self.matches[1]
	local countdownBlock = HtmlWidgets.Div{
		css = {
			display = 'block',
			['text-align'] = 'center'
		},
		children = Countdown.create{
			date = DateExt.toCountdownArg(match.timestamp, match.timezoneId, match.dateIsExact),
			finished = match.finished,
			rawdatetime = Logic.readBool(match.finished),
		}
	} or nil
	local tournament = Tournament.partialTournamentFromMatch(match)
	Array.forEach(match.opponents, function (opponent, opponentIndex)
		if opponent.type ~= Opponent.team then
			return
		end
		---@cast opponent MatchPageOpponent
		opponent.iconDisplay = OpponentDisplay.InlineTeamContainer{
			style = 'icon',
			template = opponent.template,
		}
		opponent.teamTemplateData = TeamTemplate.getRaw(opponent.template)
		opponent.seriesDots = {}
	end)
	return MatchPageHeader{
		countdownBlock = countdownBlock,
		isBestOfOne = match.bestof == 1,
		mvp = match.extradata.mvp,
		opponent1 = match.opponents[1],
		opponent2 = match.opponents[2],
		parent = tournament.pageName,
		phase = MatchGroupUtil.computeMatchPhase(match),
		stream = match.stream,
		tournamentName = tournament.fullName,
		highlighted = HighlightConditions.tournament(tournament)
	}
end

---@return Widget?
function StreamPage:create()
	if Logic.isEmpty(self.matches) then
		return
	elseif self.matches[1].bracketData.matchPage then
		return HtmlWidgets.Fragment{children = {
			'__NOTOC__',
			MatchPage(self.matches[1]):render(),
			HtmlWidgets.H3{children = 'Channel Schedule'},
			self:_createMatchTicker():query():create()
		}}
	end

	return HtmlWidgets.Fragment{children = WidgetUtil.collect(
		'__NOTOC__',
		self:_header(),
		GridWidgets.Container{gridCells = {
			GridWidgets.Cell{
				cellContent = self:render(),
				xs = 'ignore',
				sm = 'ignore',
				lg = 8,
				xl = 8,
				xxl = 9,
				xxxl = 9,
			},
			GridWidgets.Cell{
				cellContent = MatchPageAdditionalSection{
					header = 'Channel Schedule',
					children = self:_createMatchTicker():query():create():css('width', '100%')
				},
				xs = 'ignore',
				sm = 'ignore',
				lg = 4,
				xl = 4,
				xxl = 3,
				xxxl = 3,
			}
		}},
		self:createBottomContent()
	)}
end

---@private
---@return MatchTicker
function StreamPage:_createMatchTicker()
	return MatchTicker{
		additionalConditions = 'AND (' .. tostring(self:_createMatchQueryCondition()) .. ')',
		limit = 5,
		newStyle = true,
		ongoing = true,
		upcoming = true,
	}
end

---@protected
---@return string|Widget|Html|(string|Widget|Html)[]?
function StreamPage:render()
end

---@protected
---@return Widget[]?
function StreamPage:createBottomContent()
	local match = self.matches[1]

	if Array.all(match.opponents, Opponent.isTbd) then
		return
	end

	local headToHead = self:_buildHeadToHeadMatchTable()

	return WidgetUtil.collect(
		HtmlWidgets.H3{children = 'Match History'},
		HtmlWidgets.Div{
			classes = {'match-bm-match-additional'},
			children = WidgetUtil.collect(
				headToHead and MatchPageAdditionalSection{
					css = {flex = '2 0 100%'},
					header = 'Head to Head',
					bodyClasses = {'match-table-wrapper'},
					children = headToHead,
				} or nil,
				Array.map(match.opponents, function (opponent)
					local matchTable = self:_buildMatchTable(opponent)
					return MatchPageAdditionalSection{
						header = OpponentDisplay.InlineOpponent{opponent = opponent, teamStyle = 'hybrid'},
						bodyClasses = matchTable and {'match-table-wrapper'} or nil,
						children = matchTable or IconImage{
							imageLight = match.icon,
							imageDark = match.iconDark,
							size = '50x32px',
						}
					}
				end)
			)
		}
	)
end

---@private
---@param props table
---@return Html
function StreamPage:_createMatchTable(props)
	local match = self.matches[1]
	return MatchTable(Table.mergeInto({
		addCategory = false,
		edate = match.timestamp - DateExt.daysToSeconds(1) --[[ MatchTable adds 1-day offset to make edate
																inclusive, and we don't want that here ]],
		limit = 5,
		stats = false,
		vod = false,
		matchPageButtonText = 'short',
	}, props)):readConfig():query():buildDisplay()
end

---@private
---@param opponent standardOpponent
---@return Html?
function StreamPage:_buildMatchTable(opponent)
	if opponent.type ~= Opponent.solo and opponent.type ~= Opponent.team then
		return
	end
	local base = opponent.type == Opponent.team and Opponent.team or 'player'
	return self:_createMatchTable{
		['hide_tier'] = true,
		limit = 5,
		stats = false,
		tableMode = opponent.type,
		[base] = Opponent.toName(opponent),
		useTickerName = true,
	}
end

---@private
---@return Html?
function StreamPage:_buildHeadToHeadMatchTable()
	local match = self.matches[1]
	if Array.any(match.opponents, Opponent.isTbd) then
		return
	elseif match.opponents[1].type ~= match.opponents[2].type then
		return
	elseif match.opponents[1].type ~= Opponent.solo and match.opponents[1].type ~= Opponent.team then
		return
	end

	local base = match.opponents[1].type == Opponent.team and Opponent.team or 'player'

	return self:_createMatchTable{
		[base] = Opponent.toName(match.opponents[1]),
		['vs' .. base] = Opponent.toName(match.opponents[2]),
		tableMode = match.opponents[1].type,
		showOpponent = true,
		teamStyle = 'hybrid',
		useTickerName = true,
	}
end

return StreamPage

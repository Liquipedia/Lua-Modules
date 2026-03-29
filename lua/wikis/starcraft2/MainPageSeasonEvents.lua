local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Countdown = Lua.import('Module:Countdown')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local Timezone = Lua.import('Module:Timezone')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_ICON = 'InfoboxIcon_Tournament.png'
local SPOILER_DELAY = DateExt.daysToSeconds(3)
local YESTERDAY = DateExt.getCurrentTimestamp() - DateExt.daysToSeconds(1)

---@class Sc2MainPageSeasonEventsTournamentData
---@field displayName string
---@field pageName string
---@field finished boolean
---@field icon string?
---@field iconDark string?
---@field endDate integer?

local MainPageSeasonEvents = {}

---@param frame Frame
---@return Widget
function MainPageSeasonEvents.run(frame)
	local args = Arguments.getArgs(frame)

	local pageName = assert(args.event, 'No event specified')
	pageName = pageName:gsub(' ', '_')

	local tournamentData = MainPageSeasonEvents._fecthTournamentData(args, pageName)

	local iconDisplay = HtmlWidgets.Div{
		css = {
			height = '70px',
			display = 'flex',
			['justify-content'] = 'center',
			['align-items'] = 'center',
		},
		children = {
			Image{
				imageLight = tournamentData.icon,
				imageDark = tournamentData.iconDark,
				link = pageName,
				alt = tournamentData.displayName,
				size = '140x70px',
			},
		},
	}

	return HtmlWidgets.Div{
		css = {['text-align'] = 'center'},
		children = WidgetUtil.collect(
			iconDisplay,
			HtmlWidgets.Br{},
			Link{link = pageName, children = tournamentData.displayName},
			tournamentData.finished
				and MainPageSeasonEvents._winnerDisplay(tournamentData)
				or MainPageSeasonEvents._countdown(tournamentData, args)
		)
	}
end

---@param args table
---@param pageName string
---@return Sc2MainPageSeasonEventsTournamentData
function MainPageSeasonEvents._fecthTournamentData(args, pageName)
	local pageData = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = '[[pagename::' .. pageName .. ']]',
		query = 'icon, icondark, enddate, shortname, tickername, name, status',
		limit = 1,
	})
	pageData = pageData[1] or {}

	return {
		displayName = args.displayname
			or Logic.isNotEmpty(pageData.tickername) and pageData.tickername
			or Logic.isNotEmpty(pageData.shortname) and pageData.shortname
			or Logic.isNotEmpty(pageData.name) and pageData.name
			or pageName:gsub('_', ' '),
		icon = Logic.nilIfEmpty(pageData.icon) or args.icon or DEFAULT_ICON,
		iconDark = Logic.nilIfEmpty(pageData.icondark) or args.icondark or args.iconDark,
		finished = pageData.status == 'finished',
		pageName = pageName,
		endDate = DateExt.readTimestamp(pageData.enddate),
	}
end

---@param tournamentData Sc2MainPageSeasonEventsTournamentData
---@return Widget[]
function MainPageSeasonEvents._winnerDisplay(tournamentData)
	local winnerPlacement = mw.ext.LiquipediaDB.lpdb('placement', {
		conditions = '[[parent::' .. tournamentData.pageName .. ']] and [[placement::1]]',
		query = 'opponentplayers, opponenttemplate, opponenttype',
		limit = 1,
	})[1]

	local winner = winnerPlacement and Opponent.fromLpdbStruct(winnerPlacement)
	local dateDiff = DateExt.getCurrentTimestamp() - (tournamentData.endDate or 0)
	local showWinner = winner and dateDiff > SPOILER_DELAY



	return WidgetUtil.collect(
		HtmlWidgets.Br{},
		showWinner and {
			Image{
				imageLight = 'Trophy icon small.gif',
				size = '18px',
				link = '',
				alt = 'Winner',
			},
			OpponentDisplay.InlineOpponent{opponent = winner}
		} or HtmlWidgets.Span{
			classes = {'forest-green-text'},
			children = HtmlWidgets.B{children = 'Completed'},
		}
	)
end

---@param tournamentData Sc2MainPageSeasonEventsTournamentData
---@param args table
---@return Widget[]?
function MainPageSeasonEvents._countdown(tournamentData, args)
	local pages = Array.mapIndexes(function(index)
		return Logic.nilIfEmpty((args['additional_page' .. index] or ''):gsub(' ', '_'))
	end)
	table.insert(pages, tournamentData.pageName)

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionUtil.anyOf(ColumnName('parent'), pages),
		ConditionNode(ColumnName('finished'), Comparator.eq, 0),
		ConditionNode(ColumnName('date'), Comparator.gt, YESTERDAY),
		ConditionNode(ColumnName('dateexact'), Comparator.eq, 1),
	}

	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(conditions),
		query = 'date',
		order = 'date asc',
		limit = 1,
	})

	if #matches == 0 then
		return
	end

	return {
		HtmlWidgets.Br{},
		Countdown.create{date = matches[1].date .. Timezone.getTimezoneString{timezone = 'UTC'}, rawcountdown = 'true'},
	}
end

return MainPageSeasonEvents

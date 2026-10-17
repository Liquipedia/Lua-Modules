---
-- @Liquipedia
-- page=Module:DurationStats
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Tier = Lua.import('Module:Tier/Utils')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Html = Lua.import('Module:Widget/Html')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DurationStats = {}

---@param frame Frame|table
---@return Widget|string
function DurationStats.getDurationTable(frame)
	local args = Arguments.getArgs(frame)

	local conditions = tostring(DurationStats._buildConditions(args))
	local queryString = 'date, pagename, match2id, match2gameid, length, winner'

	if not conditions then return 'No data found for these conditions' end

	-- Small Data
	local smallData = mw.ext.LiquipediaDB.lpdb('match2game', {
		limit = tonumber(args.limit) or 5,
		query = queryString,
		conditions = conditions,
		order = 'length asc'
	})
	local bigData = mw.ext.LiquipediaDB.lpdb('match2game', {
		limit = tonumber(args.limit) or 5,
		query = queryString,
		conditions = conditions,
		order = 'length desc'
	})

	return Html.Fragment{
		children = {
			DurationStats._generateTable(smallData, 'Shortest Games'),
			Html.Br{},
			DurationStats._generateTable(bigData, 'Longest Games'),
		},
	}
end

---@private
---@param args any
---@return ConditionTree?
function DurationStats._buildConditions(args)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('winner'), Comparator.neq, ''),
		ConditionNode(ColumnName('length'), Comparator.neq, ''),
		ConditionNode(ColumnName('status'), Comparator.neq, 'notplayed'),
	}

	local tournaments = Array.extractValues(Table.filterByKey(args, function(key)
		return key:match('^tournament%d*$') ~= nil end))

	tournaments = Array.map(tournaments, Page.pageifyLink)

	tournaments = Logic.nilIfEmpty(tournaments)
		or DurationStats._getTournamentsFromMatches(args)
		or {(mw.title.getCurrentTitle().prefixedText:gsub(' ', '_'))}

	if Logic.isEmpty(tournaments) then return end

	return conditions:add(ConditionTree(BooleanOperator.any):add(Array.map(tournaments, function(tournament)
		return ConditionNode(ColumnName('pagename'), Comparator.eq, tournament)
	end)))
end

---@private
---@param args table
---@return string[]?
function DurationStats._getTournamentsFromMatches(args)
	if Logic.isEmpty(args.tier) then return end
	local conditions = ConditionTree(BooleanOperator.all):add(Array.append({},
		ConditionNode(ColumnName('liquipediatier'), Comparator.eq, Tier.toIdentifier(args.tier)),
		args.sdate and ConditionNode(ColumnName('date'), Comparator.ge, args.sdate) or nil,
		args.edate and ConditionNode(ColumnName('date'), Comparator.le, args.edate) or nil
	))

	local matches = mw.ext.LiquipediaDB.lpdb('match2', {
		limit = 5000,
		query = 'pagename',
		conditions = tostring(conditions),
		order = 'pagename asc',
		groupby = 'pagename asc'
	})

	return Array.map(matches, Operator.property('pagename'))
end

---@private
---@param games match2game[]
---@param title string
---@return Widget
function DurationStats._generateTable(games, title)
	return TableWidgets.Table{	
		sortable = true,
		title = title,
		columns = {
			{align = 'left'},
			{align = 'left'},
			{align = 'right'},
			{align = 'left'},
			{align = 'left'},
			{align = 'right'},
		},
		children = WidgetUtil.collect(
			--Header
			TableWidgets.Row{
				children = {
					TableWidgets.CellHeader{children = 'Date', unsortable = true},
					TableWidgets.CellHeader{children = 'Stage', unsortable = true},
					TableWidgets.CellHeader{children = 'Game #', unsortable = true},
					TableWidgets.CellHeader{children = 'Winner'},
					TableWidgets.CellHeader{children = 'Loser'},
					TableWidgets.CellHeader{children = 'Duration', unsortable = true},
				},
			},
			--Rows
			TableWidgets.TableBody{children = Array.map(games, DurationStats._buildRow)}
		)
	}
end

---@private
---@param game match2game
---@return Widget
function DurationStats._buildRow(game)
	local match = mw.ext.LiquipediaDB.lpdb('match2', {
		limit = 1,
		query = 'section, match2opponents, extradata',
		conditions = '[[opponent::!TBD]] AND [[match2id::' .. game.match2id .. ']]',
	})[1] or {}

	local gameWinner = tonumber(game.winner) or 0
	local winner = (match.match2opponents or {})[gameWinner]
	local loser = (match.match2opponents or {})[3 - gameWinner]

	local displayOpponent = function(opp)
		if not opp then return end
		return OpponentDisplay.BlockOpponent{opponent = Opponent.fromMatch2Record(opp), teamStyle = 'short'}
	end

	return TableWidgets.Row{
		children = {
			TableWidgets.Cell{children = DateExt.toYmdInUtc(game.date)},
			TableWidgets.Cell{children = Link{
				link = game.pagename,
				children = {
						match.section ~= 'Results' and match.section or (match.extradata.matchsection and match.extradata.matchsection) or 'Results'
				}
			}},
			TableWidgets.Cell{children = game.match2gameid},
			TableWidgets.Cell{children = displayOpponent(winner)},
			TableWidgets.Cell{children = displayOpponent(loser)},
			TableWidgets.Cell{children = game.length},
		}
	}
end

return DurationStats

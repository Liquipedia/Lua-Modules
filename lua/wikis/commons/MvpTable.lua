---
-- @Liquipedia
-- page=Module:MvpTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
local Operator = Lua.import('Module:Operator')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class mvpTableParsedArgs
---@field cutafter number
---@field margin number
---@field points boolean
---@field title string?
---@field matchGroupIds string[]
---@field tournaments string[]

local MvpTable = {}

---Entry point for MvpTable.
---Fetches mvpData for a given set of matchGroupIds or tournaments.
---Displays the fetched data as a table.
---@param args table
---@return Widget?
function MvpTable.run(args)
	args = args or {}
	local parsedArgs = MvpTable._parseArgs(args)
	local matchGroupIds = Array.unique(
		Array.extendWith({}, parsedArgs.matchGroupIds, MvpTable._fetchMatchGroupIds(parsedArgs))
	)
	if Logic.isEmpty(matchGroupIds) then
		return
	end
	local matches = Array.flatMap(matchGroupIds, MatchGroupUtil.fetchMatches)

	local mvpList = MvpTable.processData(matches)

	if not mvpList then
		return
	end

	return HtmlWidgets.Table{
		classes = {'wikitable', 'prizepooltable','collapsed'},
		css = {
			['text-align'] = 'center',
			['margin-top'] = args.margin .. 'px'
		},
		attributes = {
			['data-opentext'] = 'place ' .. (args.cutafter + 1) .. ' to ' .. #mvpList,
			['data-closetext'] = 'place ' .. (args.cutafter + 1) .. ' to ' .. #mvpList,
			['data-cutafter'] = args.cutafter + (String.isNotEmpty(args.title) and 1 or 0),
			['data-definedcutafter'] = ''
		},
		children = WidgetUtil.collect(
			MvpTable._mainHeader(args),
			MvpTable._subHeader(args),
			Array.map(mvpList, FnUtil.curry(MvpTable._row, args))
		)
	}
end

---Parses the entered arguments to a table that can be used better further down the line
---@param args table
---@return mvpTableParsedArgs
function MvpTable._parseArgs(args)
	local parsedArgs = {
		cutafter = tonumber(args.cutafter) or 5,
		margin = Logic.nilOr(Logic.readBoolOrNil(args.margin), true) and 20 or 0,
		points = Logic.readBool(args.points),
		title = args.title,

		matchGroupIds = {},
		tournaments = {},
	}

	for _, matchGroupId in Table.iter.pairsByPrefix(args, 'id') do
		if String.isNotEmpty(matchGroupId) then
			table.insert(parsedArgs.matchGroupIds, matchGroupId)
		end
	end

	for _, tournament in Table.iter.pairsByPrefix(args, 'tournament', {requireIndex = false}) do
		tournament = mw.ext.TeamLiquidIntegration.resolve_redirect(tournament):gsub(' ', '_')
		table.insert(parsedArgs.tournaments, tournament)
	end

	if Table.isEmpty(parsedArgs.matchGroupIds) and Table.isEmpty(parsedArgs.tournaments) then
		table.insert(parsedArgs.tournaments, mw.title.getCurrentTitle().text)
	end

	return parsedArgs
end

---@param args mvpTableParsedArgs
---@return string[]
function MvpTable._fetchMatchGroupIds(args)
	local tournamentConditions = ConditionTree(BooleanOperator.any)
	Array.forEach(args.tournaments, function (tournament)
		local page = mw.title.new(tournament)
		assert(page, 'Invalid page name "' .. tournament .. '"')
		tournamentConditions:add{
			ConditionTree(BooleanOperator.all):add{
				ConditionNode(ColumnName('pagename'), Comparator.eq, mw.ustring.gsub(page.text, ' ', '_')),
				ConditionNode(ColumnName('namespace'), Comparator.eq, page.namespace),
			},
		}
	end)

	local queryData = mw.ext.LiquipediaDB.lpdb('match2', {
		conditions = tostring(tournamentConditions),
		query = 'match2bracketid',
		limit = 5000,
	})

	return Array.unique(Array.map(queryData, Operator.property('match2bracketid')))
end

---Builds the main header of the MvpTable
---@param args mvpTableParsedArgs
---@return Widget?
function MvpTable._mainHeader(args)
	if String.isEmpty(args.title) then
		return
	end

	return HtmlWidgets.Tr{
		children = HtmlWidgets.Th{
			attributes = {colspan = 2 + (args.points and 1 or 0)},
			children = args.title
		}
	}
end

---Builds the sub header of the MvpTable
---@param args mvpTableParsedArgs
---@return Widget
function MvpTable._subHeader(args)
	return HtmlWidgets.Tr{
		children = Array.map(
			{'Player', '#MVPs', args.points and 'Points' or nil},
			function (element) return HtmlWidgets.Th{children = element} end
		)
	}
end

---Builds the display for a mvp row
---@param args mvpTableParsedArgs
---@param item {points: number, mvp: number, displayName:string?, name:string, flag:string?, team:string?}
---@return Widget
function MvpTable._row(args, item)
	return HtmlWidgets.Tr{
		children = WidgetUtil.collect(
			HtmlWidgets.Td{
				css = {['text-align'] = 'left'},
				children = OpponentDisplay.BlockOpponent{
					opponent = Opponent.readOpponentArgs{
						type = Opponent.solo,
						name = item.displayName,
						flag = item.flag,
						link = item.name,
						team = item.team and TeamTemplate.resolve(item.team, DateExt.getContextualDateOrNow()) or nil,
					},
					overflow = 'ellipsis',
					showPlayerTeam = true,
				}
			},
			HtmlWidgets.Td{children = item.mvp},
			args.points and HtmlWidgets.Td{children = item.points} or nil
		)
	}
end

---
-- Processes retrieved data
-- overwritable function via /Custom
---@param queryData MatchGroupUtilMatch[]
---@return {points: number, mvp: number, displayName:string?, name:string, flag:string?, team:string?}[]
function MvpTable.processData(queryData)
	local playerList = {}
	local mvpList = {}

	for _, item in pairs(queryData) do
		local mvp = (item.extradata or {}).mvp
		if mvp then
			for _, player in pairs(mvp.players or {}) do
				if not playerList[player.name] then
					playerList[player.name] = {
						points = 0,
						mvp = 0,
						displayName = player.displayname,
						name = player.name,
						flag = player.flag,
						team = player.team
					}
				end
				playerList[player.name].mvp = playerList[player.name].mvp + 1
				playerList[player.name].points = playerList[player.name].points + (mvp.points or 0)
			end
		end
	end

	for _, item in Table.iter.spairs(playerList, MvpTable.sortFunction) do
		table.insert(mvpList, item)
	end

	return mvpList
end

---
-- Function to sort mvps
-- exported so it can be used in /Custom
---@param tbl table
---@param a string
---@param b string
---@return boolean
function MvpTable.sortFunction(tbl, a, b)
	return tbl[a].mvp > tbl[b].mvp or
		tbl[a].mvp == tbl[b].mvp and tbl[a].name < tbl[b].name
end

return Class.export(MvpTable, {exports = {'run'}})

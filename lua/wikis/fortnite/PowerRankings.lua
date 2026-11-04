---
-- @Liquipedia
-- page=Module:PowerRankings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Currency = Lua.import('Module:Currency')
local DateExt = Lua.import('Module:Date/Ext')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local Lpdb = Lua.import('Module:Lpdb')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local PowerRankingsData = Lua.import('Module:PowerRankings/Data', {loadData = true})

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local HtmlWidgets = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local PLAYER_DATAPOINT_TYPE = 'FTN_PR'

local PowerRankings = {}

---@param updated string?
---@return Renderable
local function buildTitle(updated)
	return HtmlWidgets.Div{
		classes = {'ranking-table__top-row'},
		children = {
			HtmlWidgets.Div{
				children = WidgetUtil.collect(
					HtmlWidgets.B{children = 'Fortnite Power Rankings'},
					Logic.isNotEmpty(updated) and HtmlWidgets.Span{children = {'Last updated: ', updated}} or nil
				),
				classes = {'ranking-table__top-row-text'},
			},
			HtmlWidgets.Div{
				children = {HtmlWidgets.Span{children = 'Data by Epic Games'}},
				classes = {'ranking-table__top-row-logo-container'},
			},
		},
	}
end

---@return Renderable
local function buildFooter()
	return Link{
		link = 'Fortnite Power Rankings',
		linktype = 'internal',
		children = {
			HtmlWidgets.Div{
				children = {'See Rankings Page', Icon.makeIcon{iconName = 'goto'}},
				classes = {'ranking-table__footer-button'},
			},
		},
	}
end

---@param frame Frame
---@return VNode
function PowerRankings.main(frame)
	local args = Arguments.getArgs(frame)
	local limit = tonumber(args.limit)
	local showMore = Logic.readBool(args.showMore)

	local players = PowerRankingsData.players or {}
	if limit then
		players = Array.sub(players, 1, limit)
	end

	local updated
	if Logic.isNotEmpty(PowerRankingsData.updated) then
		updated = PowerRankingsData.updated .. ' ' .. DateExt.defaultTimezone
	end

	local rows = Array.map(players, function(entry)
		local player = {
			displayName = entry.name,
			pageName = Logic.nilIfEmpty(entry.link) or entry.name,
		}
		PlayerExt.syncPlayer(player)
		local teamTemplate = PowerRankings._fetchCurrentTeam(player.pageName)

		PowerRankings._store(player, entry)

		return TableWidgets.Row{children = {
			TableWidgets.Cell{children = HtmlWidgets.B{children = entry.rank}},
			TableWidgets.Cell{children = HtmlWidgets.B{children = Currency.formatMoney(entry.points, 0)}},
			TableWidgets.Cell{children = PlayerDisplay.BlockPlayer{player = player}},
			TableWidgets.Cell{children = teamTemplate and OpponentDisplay.BlockOpponent{opponent = {
				type = Opponent.team,
				template = teamTemplate,
				extradata = {},
			}} or nil},
		}}
	end)

	return TableWidgets.Table{
		title = buildTitle(updated),
		sortable = false,
		columns = {
			{align = 'center', sortType = 'number'},
			{align = 'center', sortType = 'number'},
			{align = 'left'},
			{align = 'left'},
		},
		footer = showMore and buildFooter() or nil,
		css = {width = '100%'},
		children = {
			TableWidgets.TableHeader{children = {
				TableWidgets.Row{children = {
					TableWidgets.CellHeader{children = 'Rank'},
					TableWidgets.CellHeader{children = 'Points'},
					TableWidgets.CellHeader{children = 'Player'},
					TableWidgets.CellHeader{children = 'Organization'},
				}},
			}},
			TableWidgets.TableBody{children = rows},
		},
	}
end

---@param pageName string
---@return string?
function PowerRankings._fetchCurrentTeam(pageName)
	local today = DateExt.getContextualDateOrNow()

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('type'), Comparator.eq, 'teamhistory'),
		ConditionNode(ColumnName('pagename'), Comparator.eq, (pageName:gsub(' ', '_'))),
		ConditionNode(ColumnName('extradata_joindate'), Comparator.neq, ''),
		ConditionNode(ColumnName('extradata_joindate'), Comparator.le, today),
	}

	local records = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = tostring(conditions),
		query = 'information, extradata',
		limit = 500,
	})

	local current = Array.filter(records, function(record)
		return record.extradata.leavedate and today < record.extradata.leavedate
	end)
	if Logic.isEmpty(current) then return nil end

	Array.sortInPlaceBy(current, function(record) return record.extradata.joindate end)
	local entry = current[#current]

	return TeamTemplate.resolve(entry.information:lower(), today)
end

---@param player standardPlayer
---@param entry {rank: integer, points: number}
function PowerRankings._store(player, entry)
	if Lpdb.isStorageDisabled() then return end
	mw.ext.LiquipediaDB.lpdb_datapoint(PLAYER_DATAPOINT_TYPE .. '_' .. player.pageName, {
		type = PLAYER_DATAPOINT_TYPE,
		name = player.pageName,
		information = entry.rank,
		extradata = {score = entry.points},
	})
end

---@param pageName string
---@param datapointType string
---@return string?
function PowerRankings.queryForInfobox(pageName, datapointType)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('type'), Comparator.eq, datapointType),
		ConditionNode(ColumnName('name'), Comparator.eq, pageName),
	}

	local data = mw.ext.LiquipediaDB.lpdb('datapoint', {
		limit = 1,
		order = 'date DESC',
		conditions = tostring(conditions),
		query = 'information, extradata',
	})[1]

	if not data then return end

	local points = data.extradata.score
	local rank = data.information
	if not points or not rank then return end

	points = Currency.formatMoney(points, datapointType == PLAYER_DATAPOINT_TYPE and 0 or 1)

	return points .. ' (Rank #' .. rank .. ')'
end

return PowerRankings

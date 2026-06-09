---
-- @Liquipedia
-- page=Module:PowerRankings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local DateExt = Lua.import('Module:Date/Ext')
local Flags = Lua.import('Module:Flags')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local PlayerExt = Lua.import('Module:Player/Ext')
local String = Lua.import('Module:StringUtils')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local PowerRankingsData = Lua.import('Module:PowerRankings/Data', {loadData = true})
local DISPLAY_PAGE = 'Fortnite Power Rankings'

local CONTAINER_STYLE = 'display: inline-flex; align-items: center; white-space: nowrap; '
	.. 'line-height: 1; font-size: 1em; vertical-align: middle;'
local FLAG_SPACING = '5px'

local p = {}

local function renderPlayer(name, link)
	if String.isEmpty(name) then
		return ''
	end
	local date = DateExt.toYmdInUtc(DateExt.getContextualDateOrNow())
	local pageNameFromLink, displayNameFromLink = PlayerExt.extractFromLink(name)
	local player = {
		displayName = displayNameFromLink or name,
		pageName = String.nilIfEmpty(link) or pageNameFromLink,
	}
	PlayerExt.syncPlayer(player, {date = date})

	local items = {}
	if String.isNotEmpty(player.flag) then
		local flagIcon = String.nilIfEmpty(Flags.Icon{flag = player.flag, shouldLink = false})
		if flagIcon then
			items[#items + 1] = string.format(
				'<span style="display: inline-flex; align-items: center; margin-right: %s;">%s</span>',
				FLAG_SPACING, flagIcon)
		end
	end
	items[#items + 1] = string.format('<span>[[%s|%s]]</span>', player.pageName, player.displayName)

	return string.format('<span style="%s">%s</span>', CONTAINER_STYLE, table.concat(items))
end

local function queryPlayerOrg(name)
	if Logic.isEmpty(name) then
		return ''
	end
	local conditions = ConditionTree(BooleanOperator.any):add{
		ConditionNode(ColumnName('pagename'), Comparator.eq, Page.pageifyLink(name)),
		ConditionNode(ColumnName('id'), Comparator.eq, name),
	}
	local row = mw.ext.LiquipediaDB.lpdb('player', {
		query = 'team',
		conditions = conditions:toString(),
		limit = 1,
	})[1] or {}
	return row.team or ''
end

local function renderOrg(name, frame)
	local org = queryPlayerOrg(name)
	if Logic.isEmpty(org) then
		return ''
	end
	return frame:expandTemplate{title = 'Team', args = {org}}
end

local function buildTitle(updated)
	local textChildren = {HtmlWidgets.B{children = 'Fortnite Power Rankings'}}
	if Logic.isNotEmpty(updated) then
		textChildren[#textChildren + 1] = HtmlWidgets.Span{children = 'Last updated: ' .. updated}
	end
	return HtmlWidgets.Div{
		children = {
			HtmlWidgets.Div{children = textChildren, classes = {'ranking-table__top-row-text'}},
			HtmlWidgets.Div{
				children = {HtmlWidgets.Span{children = 'Data by Epic Games'}},
				classes = {'ranking-table__top-row-logo-container'},
			},
		},
		classes = {'ranking-table__top-row'},
	}
end

local function buildFooter()
	return Link{
		link = DISPLAY_PAGE,
		linktype = 'internal',
		children = {
			HtmlWidgets.Div{
				children = {'See Rankings Page', Icon.makeIcon{iconName = 'goto'}},
				classes = {'ranking-table__footer-button'},
			},
		},
	}
end

function p.main(frame)
	local args = Arguments.getArgs(frame)
	local limit = tonumber(args.limit)
	local showMore = Logic.readBool(args.showMore)

	local players = PowerRankingsData.players or {}

	local updated = ''
	if Logic.isNotEmpty(PowerRankingsData.updated) then
		updated = PowerRankingsData.updated .. ' ' .. frame:expandTemplate{title = 'Abbr/UTC'}
	end

	local rows = {}
	for i, player in ipairs(players) do
		if limit and i > limit then break end
		local name = player.name or ''
		local link = Logic.nilIfEmpty(player.link)
		local orgKey = link or name

		rows[#rows + 1] = TableWidgets.Row{children = {
			TableWidgets.Cell{children = HtmlWidgets.B{children = player.rank}},
			TableWidgets.Cell{children = HtmlWidgets.B{children = player.points}},
			TableWidgets.Cell{children = renderPlayer(name, link)},
			TableWidgets.Cell{children = renderOrg(orgKey, frame)},
		}}
	end

	return tostring(TableWidgets.Table{
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
	})
end

return p

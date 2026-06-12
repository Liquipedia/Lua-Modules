---
-- @Liquipedia
-- page=Module:PowerRankings
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Icon = Lua.import('Module:Icon')
local Logic = Lua.import('Module:Logic')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local HtmlWidgets = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local PowerRankingsData = Lua.import('Module:PowerRankings/Data', {loadData = true})

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
		local teamTemplate = PlayerExt.syncTeam(player.pageName)

		return TableWidgets.Row{children = {
			TableWidgets.Cell{children = HtmlWidgets.B{children = entry.rank}},
			TableWidgets.Cell{children = HtmlWidgets.B{children = entry.points}},
			TableWidgets.Cell{children = PlayerDisplay.BlockPlayer{player = player}},
			TableWidgets.Cell{children = teamTemplate and OpponentDisplay.BlockOpponent{opponent = {
				type = Opponent.team,
				template = teamTemplate,
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

return PowerRankings

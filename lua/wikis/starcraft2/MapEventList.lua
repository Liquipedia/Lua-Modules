---
-- @Liquipedia
-- page=Module:MapEventList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local LeagueIcon = Lua.import('Module:LeagueIcon')
local Logic = Lua.import('Module:Logic')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')

local MapEventList = {}

---@param frame Frame
---@return Widget?
function MapEventList.run(frame)
	local args = Arguments.getArgs(frame)
	local mapName = (args.map or mw.title.getCurrentTitle().text):gsub(' ', '_')

	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('maps'), Comparator.neq, ''),
		ConditionNode(ColumnName('liquipediatier'), Comparator.eq, 1),
		ConditionNode(ColumnName('liquipediatiertype'), Comparator.eq, ''),
	}

	local data = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = tostring(conditions),
		query = 'pagename, maps, startdate, enddate, icon, icondark, name, extradata',
		order = 'enddate desc',
		limit = 5000,
	})

	if not data or not data[1] then
		return
	end

	return HtmlWidgets.Fragment{children = {
		HtmlWidgets.H3{children = 'Played in Premier Tournaments'},
		TableWidgets.Table{
			sortable = true,
			columns = Array.rep({}, 4),
			children = {
				MapEventList._header(),
				TableWidgets.TableBody{children = Array.map(data, FnUtil.curry(MapEventList._row, mapName))},
			},
		}
	}}
end

---@private
---@return Widget
function MapEventList._header()
	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = {
			TableWidgets.CellHeader{children = {'Start date'}},
			TableWidgets.CellHeader{children = {'End date'}},
			TableWidgets.CellHeader{colspan = 2, children = {'Tournament'}},
		}}
	}}
end

---@private
---@param mapName string
---@param item {maps: string, pagename: string, startdate: string, enddate: string,
---icon: string, icondark: string, name: string}
---@return Widget?
function MapEventList._row(mapName, item)
	local maps = Json.parseIfTable(item.maps) or {}
	if Logic.isEmpty(maps) then
		return
	end

	if Array.all(maps, function(mapData)
		return (mapData.link:gsub(' ', '_')) ~= mapName
	end) then return end

	return TableWidgets.Row{children = {
		TableWidgets.Cell{children = item.startdate},
		TableWidgets.Cell{children = item.enddate},
		TableWidgets.Cell{children = LeagueIcon.display{
			icon = item.icon,
			iconDark = item.icondark,
			link = item.pagename,
			name = item.name,
			options = {noTemplate = true},
		}},
		TableWidgets.Cell{children = Link{link = item.pagename, children = item.name or item.pagename:gsub('_', ' ')}},
	}}
end

return MapEventList

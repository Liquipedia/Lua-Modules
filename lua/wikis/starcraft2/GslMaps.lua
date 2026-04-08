---
-- @Liquipedia
-- page=Module:GslMaps
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Operator = Lua.import('Module:Operator')
local Json = Lua.import('Module:Json')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local GslMaps = {}

---@return Widget
function GslMaps.run()
	local seasons, maps = GslMaps._fetch()

	return TableWidgets.Table{
		sortable = true,
		children = {
			TableWidgets.TableHeader{children = GslMaps._header(seasons)},
			TableWidgets.TableBody{children = Array.map(maps, FnUtil.curry(GslMaps._row, #seasons))},
		},
	}
end

---@private
---@return Widget[]
---@return {display: Widget, seasons: table<integer, true>, sortKey: string}[]
function GslMaps._fetch()
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('seriespage'), Comparator.eq, 'Global_StarCraft_II_League'),
		ConditionNode(ColumnName('sortdate'), Comparator.gt, '2016-01-01'),
		ConditionNode(ColumnName('liquipediatiertype'), Comparator.neq, 'Qualifier'),
	}

	local queryData = mw.ext.LiquipediaDB.lpdb('tournament', {
		conditions = tostring(conditions),
		query = 'tickername, maps, pagename',
		limit = 5000,
		order = 'sortdate asc',
	})

	---@type table<string, {display: Widget, seasons: table<integer, true>}>
	local maps = {}
	local seasons = Array.map(queryData, function(tournament, tournamentIndex)
		Array.forEach(Json.parseIfString(tournament.maps) or {}, function(mapInfo)
			maps[mapInfo.link] = maps[mapInfo.link] or {
				display = Link{link = mapInfo.link, children = mapInfo.displayname},
				seasons = {},
				sortKey = mapInfo.link:lower(),
			}
			maps[mapInfo.link].seasons[tournamentIndex] = true
		end)
		local displayName = tournament.tickername
			:gsub('AfreecaTV GSL Super Tournament', 'ST')
			:gsub('GSL Season', 'S')
			:gsub(': Code S', '')
			:gsub('GSL vs the World', 'GSLvW')
		return Link{link = tournament.pagename, children = displayName}
	end)

	local mapsArray = Array.extractValues(maps)
	Array.sortInPlaceBy(mapsArray, Operator.property('sortKey'))

	return seasons, mapsArray
end

---@private
---@param seasons Widget[]
---@return Widget
function GslMaps._header(seasons)
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Map'},
			Array.map(seasons, function(season)
				return TableWidgets.CellHeader{children = season}
			end)
		)
	}
end

---@private
---@param numberOfSeasons integer
---@param mapData {display: Widget, seasons: table<integer, true>}
---@return Widget
function GslMaps._row(numberOfSeasons, mapData)
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = mapData.display},
			Array.map(Array.range(1, numberOfSeasons), function(seasonIndex)
				return TableWidgets.Cell{
					classes = {mapData.seasons[seasonIndex] and 'bg-up' or nil},
					attributes = {['data-sort-value'] = mapData.seasons[seasonIndex] and -1 or 0},
					children = ''
				}
			end)
		)
	}
end

return GslMaps

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Game = Lua.import('Module:Game')
local Operator = Lua.import('Module:Operator')
local Seasons = Lua.import('Module:Map Seasons', {loadData = true})
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_DATE = '2999-01-01'

local LadderMapsTimeLine = {}

---@param frame Frame
---@return Widget
function LadderMapsTimeLine.run(frame)
	local args = Arguments.getArgs(frame)
	local mode = (args.mode or '1v1'):lower()
	local game = Game.toIdentifier{game = args.game, useDefault = false}
	assert(game, 'Missing or invalid game input')

	local seasons, maps = LadderMapsTimeLine._fetch(mode, game)

	return TableWidgets.Table{
		sortable = true,
		children = {
			TableWidgets.TableHeader{children = LadderMapsTimeLine._header(seasons)},
			TableWidgets.TableBody{children = Array.map(maps, FnUtil.curry(LadderMapsTimeLine._row, Table.size(seasons)))},
		},
	}
end

---@private
---@param mode string
---@param game string?
---@return {name: string, date_value: string}[]
---@return {display: Widget, seasons: table<integer, true>, sortKey: string, introduction: string[], removal: string[]}[]
function LadderMapsTimeLine._fetch(mode, game)
	local conditions = ConditionTree(BooleanOperator.all):add{
		ConditionNode(ColumnName('type'), Comparator.eq, 'maphistory'),
		ConditionNode(ColumnName('information'), Comparator.eq, mode .. (game ~= 'lotv' and game or '')),
	}

	local queryData = mw.ext.LiquipediaDB.lpdb('datapoint', {
		conditions = tostring(conditions),
		query = 'name, pagename, extradata',
		order = 'date asc',
		limit = 5000,
	})

	local seasons = Seasons[game]

	---@type table<string, {display: Widget, seasons: table<integer, true>, introduction: string[],
	---removal: string[], sortKey: string}>
	local maps = {}
	Array.map(queryData, function(mapHistory)
		if not maps[mapHistory.pagename] then
			maps[mapHistory.pagename] = {
				display = Link{link = mapHistory.pagename, children = mapHistory.name},
				seasons = {},
				introduction = {},
				removal = {},
				sortKey = mapHistory.pagename:lower(),
			}
		end
		local startDate = mapHistory.extradata.sdate
		local endDate = mapHistory.extradata.edate
		Array.forEach(seasons, function(season, seasonIndex)
			local seasonStart = season.date_value
			local seasonEnd = (seasons[seasonIndex + 1] or {date_value = DEFAULT_DATE}).date_value

			-- started before season and ended after season
			if startDate < seasonStart and endDate > seasonEnd then
				maps[mapHistory.pagename].seasons[seasonIndex] = true
			-- started within the season
			elseif startDate > seasonStart and startDate < seasonEnd then
				maps[mapHistory.pagename].seasons[seasonIndex] = true
			-- end within the season
			elseif endDate < seasonStart and endDate < seasonEnd then
				maps[mapHistory.pagename].seasons[seasonIndex] = true
			end
		end)
		table.insert(maps[mapHistory.pagename].introduction, startDate)
		table.insert(maps[mapHistory.pagename].removal, endDate)
	end)

	local mapsArray = Array.extractValues(maps)
	Array.sortInPlaceBy(mapsArray, Operator.property('sortKey'))

	return seasons, mapsArray
end

---@private
---@param seasons {name: string, date_value: string}[]
---@return Widget
function LadderMapsTimeLine._header(seasons)
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Map'},
			TableWidgets.CellHeader{children = 'Introduction'},
			TableWidgets.CellHeader{children = 'Removal'},
			Array.map(seasons, function(season)
				return TableWidgets.CellHeader{children = season.name}
			end)
		)
	}
end

---@private
---@param numberOfSeasons integer
---@param mapData {display: Widget, seasons: table<integer, true>, introduction: string[], removal: string[]}
---@return Widget
function LadderMapsTimeLine._row(numberOfSeasons, mapData)
	---@param dates string[]
	---@return Renderable[]
	local displayDates = function(dates)
		dates = Array.map(dates, function(date) return date == DEFAULT_DATE and 'TBD' or date end)
		return Array.interleave(dates, HtmlWidgets.Br{})
	end

	return TableWidgets.Row{
		children = WidgetUtil.collect(
			TableWidgets.Cell{children = mapData.display},
			TableWidgets.Cell{children = displayDates(mapData.introduction)},
			TableWidgets.Cell{children = displayDates(mapData.removal)},
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

return LadderMapsTimeLine

---
-- @Liquipedia
-- page=Module:Widget/POIDraft/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Ordinal = Lua.import('Module:Ordinal')

local Component = Lua.import('Module:Widget/Component')
local HtmlWidgets = Lua.import('Module:Widget/Html')
local PoiMap = Lua.import('Module:Widget/POIDraft/POIMap')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local Team = Lua.import('Module:Widget/TeamDisplay/Block')

local Abbr = HtmlWidgets.Abbr
local I = HtmlWidgets.I

---@type table<string, PoiMapData>
local MAPS_DATA = Lua.import('Module:POIDraft/POIMap/Data', { loadData = true })

local Helpers = {}

---@class WidgetPoiDraftProps
---@field map string
---@field [string] any

---@private
---@param props WidgetPoiDraftProps
---@param poiName string
---@param contextDate string|number
---@return Renderable?
function Helpers._row(props, poiName, contextDate)
	local team = props[poiName .. ' team']

	if Logic.isEmpty(team) then
		return nil
	end

	---@cast team string

	local isFirstPick = tostring(props[poiName .. ' rotation']) == '1'
	local priorityIcon = isFirstPick and I {
		classes = { 'fas', 'fa-check', 'forest-green-text' },
	} or nil

	return TableWidgets.Row {
		classes = { 'brkts-opponent-hover' },
		attributes = { ['aria-label'] = team },
		children = {
			TableWidgets.Cell { children = priorityIcon },
			TableWidgets.Cell { children = Ordinal.toOrdinal(props[poiName .. ' seed']) },
			TableWidgets.Cell {
				children = Team {
					style = 'short',
					name = team,
					date = contextDate,
				},
			},
			TableWidgets.Cell { children = poiName },
		},
	}
end

---@param props WidgetPoiDraftProps
---@return Renderable?
local function PoiDraft(props)
	local mapData = MAPS_DATA[props.map]

	if not mapData then
		return nil
	end

	local contextDate = DateExt.getContextualDateOrNow()

	local rows = {}
	Array.forEach(PoiMap.getDraftPois(mapData.pois, props, contextDate), function(poi)
		local row = Helpers._row(props, poi.name, contextDate)
		if row then
			table.insert(rows, row)
		end
	end)

	if Logic.isEmpty(rows) then
		return nil
	end

	return TableWidgets.Table {
		striped = true,
		columns = {
			{ shrink = true, align = 'center' },
			{ shrink = true, align = 'center' },
			{ align = 'left' },
			{ align = 'left' },
		},
		children = {
			TableWidgets.TableHeader {
				children = {
					TableWidgets.Row {
						children = {
							TableWidgets.CellHeader {
								children = Abbr {
									title = 'First Choice Priority Pick',
									children = '1st',
								},
							},
							TableWidgets.CellHeader { children = 'Pick' },
							TableWidgets.CellHeader { children = 'Team' },
							TableWidgets.CellHeader {
								children = Abbr {
									title = 'Point of Interest',
									children = 'POI',
								},
							},
						},
					},
				},
			},
			TableWidgets.TableBody {
				children = rows,
			},
		},
	}
end

return Component.component(PoiDraft)

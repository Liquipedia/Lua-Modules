---
-- @Liquipedia
-- page=Module:Widget/POIDraft/Table
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Ordinal = Lua.import('Module:Ordinal')

local PoiMap = Lua.import('Module:Widget/POIDraft/POIMap')
local Team = Lua.import('Module:Widget/TeamDisplay/Block')
local Widget = Lua.import('Module:Widget')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local HtmlWidgets = Lua.import('Module:Widget/Html')

local Abbr = HtmlWidgets.Abbr
local I = HtmlWidgets.I

---@type table<string, PoiMapData>
local MAPS_DATA = Lua.import('Module:Widget/POIDraft/POIMap/Data', {loadData = true})

---@class WidgetPoiDraftProps
---@field map string
---@field [string] any

---@class WidgetPoiDraft: Widget
---@operator call(WidgetPoiDraftProps): WidgetPoiDraft
local PoiDraft = Class.new(Widget)

---@return Renderable?
function PoiDraft:render()
	local props = self.props
	local mapData = MAPS_DATA[props.map]

	if not mapData then
		return nil
	end

	local contextDate = DateExt.getContextualDateOrNow()

	local rows = {}
	Array.forEach(PoiMap.getDraftPois(mapData.pois, props, contextDate), function(poi)
		local row = self:_row(poi.name, contextDate)
		if row then
			table.insert(rows, row)
		end
	end)

	if Logic.isEmpty(rows) then
		return nil
	end

	return TableWidgets.Table{
		striped = true,
		columns = {
			{shrink = true, align = 'center'},
			{shrink = true, align = 'center'},
			{align = 'left'},
			{align = 'left'},
		},
		children = {
			TableWidgets.TableHeader{
				children = {
					TableWidgets.Row{
						children = {
							TableWidgets.CellHeader{
								children = Abbr{
									title = 'First Choice Priority Pick',
									children = '1st',
								},
							},
							TableWidgets.CellHeader{children = 'Pick'},
							TableWidgets.CellHeader{children = 'Team'},
							TableWidgets.CellHeader{
								children = Abbr{
									title = 'Point of Interest',
									children = 'POI',
								},
							},
						},
					},
				},
			},
			TableWidgets.TableBody{
				children = rows,
			},
		},
	}
end

---@private
---@param poiName string
---@param contextDate string|number
---@return Renderable?
function PoiDraft:_row(poiName, contextDate)
	local props = self.props
	local team = props[poiName .. ' team']

	if Logic.isEmpty(team) then
		return nil
	end

	---@cast team string

	local isFirstPick = tostring(props[poiName .. ' rotation']) == '1'
	local priorityIcon = isFirstPick and I{
		classes = {'fas', 'fa-check', 'forest-green-text'},
	} or nil

	return TableWidgets.Row{
		classes = {'brkts-opponent-hover'},
		attributes = {['aria-label'] = team},
		children = {
			TableWidgets.Cell{children = priorityIcon},
			TableWidgets.Cell{children = Ordinal.toOrdinal(props[poiName .. ' seed'])},
			TableWidgets.Cell{
				children = Team{
					style = 'short',
					name = team,
					date = contextDate,
				},
			},
			TableWidgets.Cell{children = poiName},
		},
	}
end

return PoiDraft

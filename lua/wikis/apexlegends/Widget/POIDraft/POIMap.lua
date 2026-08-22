---
-- @Liquipedia
-- page=Module:Widget/POIDraft/POIMap
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local HtmlWidgets = Lua.import('Module:Widget/Html')
local Image = Lua.import('Module:Widget/Image/Icon/Image')
local PoiLabel = Lua.import('Module:Widget/POIDraft/POILabel')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Div = HtmlWidgets.Div

---@type table<string, PoiMapData>
local MAPS_DATA = Lua.import('Module:POIDraft/POIMap/Data', { loadData = true })

local Helpers = {}

---@class PoiMapProps
---@field map string
---@field [string] any

---@private
---@param item POIDraftDateBoundItem
---@param contextTimestamp integer?
---@return boolean
local function isActiveOnDate(item, contextTimestamp)
	if not item.startDate and not item.endDate then
		return true
	end

	if not contextTimestamp then
		return false
	end

	local startTimestamp = item.startDate and DateExt.readTimestampOrNil(item.startDate)
	local endTimestamp = item.endDate and DateExt.readTimestampOrNil(item.endDate)

	return (not startTimestamp or contextTimestamp >= startTimestamp)
		and (not endTimestamp or contextTimestamp < endTimestamp)
end

---@generic T: POIDraftDateBoundItem
---@param items T[]
---@param date string|number?
---@return T?
function Helpers.filterActiveItem(items, date)
	local contextTimestamp = DateExt.readTimestampOrNil(date)
	local defaultItem

	for _, item in ipairs(items) do
		if not item.startDate and not item.endDate then
			defaultItem = item
		elseif isActiveOnDate(item, contextTimestamp) then
			return item
		end
	end

	return defaultItem
end

---@generic T: POIDraftDateBoundItem
---@param items T[]
---@param date string|number?
---@return T[]
function Helpers.filterActiveItems(items, date)
	local contextTimestamp = DateExt.readTimestampOrNil(date)

	return Array.filter(items, function(item)
		return isActiveOnDate(item, contextTimestamp)
	end)
end

---@param pois PoiData[]
---@param args table<string, any>
---@param date string|number?
---@return PoiData[]
function Helpers.getDraftPois(pois, args, date)
	local activePois = Helpers.filterActiveItems(pois, date)

	return Array.filter(activePois, function(poi)
		if poi.hideIfAny then
			for _, argKey in ipairs(poi.hideIfAny) do
				if Logic.isNotEmpty(args[argKey]) then
					return false
				end
			end
		end

		if poi.hideIfAllMissing then
			local allMissing = true
			for _, argKey in ipairs(poi.hideIfAllMissing) do
				if Logic.isNotEmpty(args[argKey]) then
					allMissing = false
					break
				end
			end
			if allMissing then
				return false
			end
		end

		return true
	end)
end

---@private
---@param mapData PoiMapData
---@param contextDate string|number
---@return string?
function Helpers._getCurrentMapImage(mapData, contextDate)
	local activeImage = Helpers.filterActiveItem(mapData.image, contextDate)
	return activeImage and activeImage.file or nil
end

---@private
---@param props PoiMapProps
---@param mapData PoiMapData
---@param currentImage string
---@param isMobile boolean
---@param contextDate string|number
---@return HtmlNode
function Helpers._renderMapContainer(props, mapData, currentImage, isMobile, contextDate)
	local width = isMobile and mapData.mobileWidth or mapData.width
	local poisToRender = Helpers.getDraftPois(mapData.pois, props, contextDate)

	return Div {
		classes = {
			isMobile and 'mobile-only' or 'mobile-hide',
			'nounderlines',
			'dynamicmap',
			'transparent-bg',
		},
		css = {
			position = 'relative',
			width = tostring(width) .. 'px',
			margin = 'auto',
		},
		children = WidgetUtil.collect(
			Div {
				children = {
					Image {
						imageLight = currentImage,
						size = tostring(width) .. 'px',
						alt = mapData.name,
					},
				},
			},
			Array.map(poisToRender, function(poiData)
				return PoiLabel {
					poiData = poiData,
					draftArgs = props,
					date = contextDate,
					isMobile = isMobile,
					scale = width,
				}
			end)
		),
	}
end

---@param props PoiMapProps
---@return Renderable?
local function PoiMap(props)
	local mapData = MAPS_DATA[props.map]
	if not mapData then
		return nil
	end

	local contextDate = DateExt.getContextualDateOrNow()

	local currentImage = Helpers._getCurrentMapImage(mapData, contextDate)
	if not currentImage then
		return nil
	end

	return TableWidgets.Table {
		columns = {
			{ align = 'center' },
		},
		children = {
			TableWidgets.TableHeader {
				children = {
					TableWidgets.Row {
						children = {
							TableWidgets.CellHeader { children = mapData.name },
						},
					},
				},
			},
			TableWidgets.TableBody {
				children = {
					TableWidgets.Row {
						children = {
							TableWidgets.Cell {
								css = { padding = 0 },
								children = WidgetUtil.collect(
									Helpers._renderMapContainer(props, mapData, currentImage, false, contextDate),
									Helpers._renderMapContainer(props, mapData, currentImage, true, contextDate)
								),
							},
						},
					},
				},
			},
		},
	}
end

local PoiMapComponent = Component.component(PoiMap)
PoiMapComponent.filterActiveItem = Helpers.filterActiveItem
PoiMapComponent.filterActiveItems = Helpers.filterActiveItems
PoiMapComponent.getDraftPois = Helpers.getDraftPois

return PoiMapComponent

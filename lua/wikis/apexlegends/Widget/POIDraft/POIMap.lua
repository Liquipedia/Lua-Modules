---
-- @Liquipedia
-- page=Module:Widget/POIDraft/POIMap
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')

local Image = Lua.import('Module:Widget/Image/Icon/Image')
local PoiLabel = Lua.import('Module:Widget/POIDraft/POILabel')
local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local HtmlWidgets = Lua.import('Module:Widget/Html')

local Div = HtmlWidgets.Div

---@class POIDraftDateBoundItem
---@field startDate string?
---@field endDate string?

---@type table<string, PoiMapData>
local MAPS_DATA = Lua.import('Module:Widget/POIDraft/POIMap/Data', {loadData = true})

---@class PoiMapProps
---@field map string
---@field [string] any

---@class PoiMap: Widget
---@operator call(PoiMapProps): PoiMap
local PoiMap = Class.new(Widget)

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
function PoiMap.filterActiveItem(items, date)
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
function PoiMap.filterActiveItems(items, date)
	local contextTimestamp = DateExt.readTimestampOrNil(date)

	return Array.filter(items, function(item)
		return isActiveOnDate(item, contextTimestamp)
	end)
end

---@param pois PoiData[]
---@param args table<string, any>
---@param date string|number?
---@return PoiData[]
function PoiMap.getDraftPois(pois, args, date)
	local activePois = PoiMap.filterActiveItems(pois, date)

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
function PoiMap:_getCurrentMapImage(mapData, contextDate)
	local activeImage = PoiMap.filterActiveItem(mapData.image, contextDate)
	return activeImage and activeImage.file or nil
end

---@return Renderable?
function PoiMap:render()
	local mapData = MAPS_DATA[self.props.map]
	if not mapData then
		return nil
	end

	local contextDate = DateExt.getContextualDateOrNow()

	local currentImage = self:_getCurrentMapImage(mapData, contextDate)
	if not currentImage then
		return nil
	end

	return TableWidgets.Table{
		columns = {
			{align = 'center'},
		},
		children = {
			TableWidgets.TableHeader{
				children = {
					TableWidgets.Row{
						children = {
							TableWidgets.CellHeader{children = mapData.name},
						},
					},
				},
			},
			TableWidgets.TableBody{
				children = {
					TableWidgets.Row{
						children = {
							TableWidgets.Cell{
								css = {padding = 0},
								children = WidgetUtil.collect(
									self:_renderMapContainer(mapData, currentImage, false, contextDate),
									self:_renderMapContainer(mapData, currentImage, true, contextDate)
								),
							},
						},
					},
				},
			},
		},
	}
end

---@private
---@param mapData PoiMapData
---@param currentImage string
---@param isMobile boolean
---@param contextDate string|number
---@return Renderable
function PoiMap:_renderMapContainer(mapData, currentImage, isMobile, contextDate)
	local width = isMobile and mapData.mobileWidth or mapData.width
	local poisToRender = self:_getPoisToRender(mapData, contextDate)

	return Div{
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
			Div{
				children = {
					Image{
						imageLight = currentImage,
						size = tostring(width) .. 'px',
						alt = mapData.name,
					},
				},
			},
			Array.map(poisToRender, function(poiData)
				return PoiLabel{
					poiData = poiData,
					draftArgs = self.props,
					date = contextDate,
					isMobile = isMobile,
					scale = width,
				}
			end)
		),
	}
end

---@private
---@param mapData PoiMapData
---@param contextDate string|number
---@return PoiData[]
function PoiMap:_getPoisToRender(mapData, contextDate)
	return PoiMap.getDraftPois(mapData.pois, self.props, contextDate)
end

return PoiMap

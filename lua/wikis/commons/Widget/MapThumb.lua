---
-- @Liquipedia
-- page=Module:Widget/MapThumb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Map = Lua.import('Module:Map')
local Page = Lua.import('Module:Page')

---for variations and data of maps that have no page
---@type table<string, StandardMap>
local MapData = Lua.requireIfExists('Module:MapPoolTable/Data', {loadData = true}) or {}

local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Widget = Lua.import('Module:Widget')

local PLACEHOLDER_IMAGE = 'MapImagePlaceholder.jpg'

---@class MapThumb: Widget
---@operator call(table): MapThumb
---@field props {map: string?, size: string|integer}
local MapThumb = Class.new(Widget)
MapThumb.defaultProps = {
	size = 'x120px',
}

---@return Widget?
function MapThumb:render()
	if Logic.isEmpty(self.props.map) then
		return
	end

	local map = self:_getMapData()
	assert(map and map.image, 'Invalid map "' .. self.props.map .. '"')

	return Image{
		imageLight = map.image or PLACEHOLDER_IMAGE,
		imageDark = map.imageDark,
		link = map.pageName,
		size = self.props.size,
		alt = map.displayName or map.pageName,
	}
end

---@return StandardMap?
function MapThumb:_getMapData()
	local map = Map.getMapByPageName(Page.pageifyLink(self.props.map))
	if map then
		return map
	end
	local key = self.props.map
		:gsub('_', ' ')
		:gsub('%s*LE$', '')
		:gsub('%s*TE$', '')
		:gsub('%s*CE$', '')
		:gsub('%s%([mM]ap%)$', '')
		:lower()
	return MapData[self.props.map] or MapData[key]
end

return MapThumb

---
-- @Liquipedia
-- page=Module:Widget/MapThumb
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')
local Map = Lua.import('Module:Map')
local Page = Lua.import('Module:Page')

---for variations and data of maps that have no page
---@type table<string, StandardMap>
local MapData = Lua.requireIfExists('Module:MapPoolTable/Data', {loadData = true}) or {}

local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Component = Lua.import('Module:Widget/Component')

local PLACEHOLDER_IMAGE = 'MapImagePlaceholder.jpg'

local defaultProps = {
	size = 'x120px',
}

---@param mapInput string
---@return StandardMap?
local function getMapData(mapInput)
	local map = Map.getMapByPageName(Page.pageifyLink(mapInput))
	if map then
		return map
	end
	local key = mapInput
		:gsub('_', ' ')
		:gsub('%s*LE$', '')
		:gsub('%s*TE$', '')
		:gsub('%s*CE$', '')
		:gsub('%s%([mM]ap%)$', '')
		:lower()
	return MapData[map] or MapData[key]
end

---@param props {map: string?, size: string|integer}
---@return Renderable?
local function MapThumb(props)
	if Logic.isEmpty(props.map) then
		return
	end

	local map = getMapData(props.map)
	assert(map, 'Invalid map "' .. props.map .. '"')

	return Image{
		imageLight = map.image or PLACEHOLDER_IMAGE,
		imageDark = map.imageDark,
		link = map.pageName,
		size = tostring(props.size),
		alt = map.displayName or map.pageName,
	}
end



return Component.component(MapThumb, defaultProps)

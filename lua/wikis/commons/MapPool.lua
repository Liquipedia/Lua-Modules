---
-- @Liquipedia
-- page=Module:MapPoolTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

---for variations and data of maps that have no page
---@type table<string, StandardMap>
local MapData = Lua.requireIfExists('Module:MapPoolTable/Data', {loadData = true}) or {}

local Image = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_THUMB_SIZE = 'x120px'
local PLACEHOLDER_IMAGE = 'MapImagePlaceholder.jpg'

---@class MapPoolConfig
---@field note string?
---@field showAuthor boolean
---@field sort boolean
---@field size string
---@field title string?
---@field tournament string?

---@class MapPoolTable
---@operator call(Frame): MapPoolTable
---@field args table
---@field config MapPoolConfig
---@field mapCategories {maps: StandardMap, title: string?}[]
local MapPoolTable = Class.new(function(self, frame)
	local args = Arguments.getArgs(frame)
	self.config = self:_readConfig(args)
	self.mapCategories = self:_readManualInput(args)
	if Logic.isEmpty(self.mapCategories) then
		self.mapCategories = self:_readFromInfobox(args)
	end
end)

---@param frame Frame
---@return Widget?
function MapPoolTable.run(frame)
	return MapPoolTable(frame):display()
end

---@param args table
---@return MapPoolConfig
function MapPoolTable:_readConfig(args)
	return {
		note = args.note,
		showAuthor = Logic.readBool(args.author),
		sort = Logic.readBool(args.sort),
		size = args.size,
		title = args.title,
	}
end

---@param args table
---@return {maps: StandardMap, title: string?}[]
function MapPoolTable:_readManualInput(args)
	local categories = Array.mapIndexes(function(categoryIndex)
		return MapPoolTable._readManualMaps(Json.parseIfTable(args['category' .. categoryIndex]) or {}, true)
	end)
	if Logic.isNotEmpty(categories) then
		return categories
	end
	return {self:_readManualMaps(args)}
end

---@param inputs table
---@param requireTitle boolean?
---@return {maps: StandardMap, title: string?}
function MapPoolTable:_readManualMaps(inputs, requireTitle)
	local maps = Logic.nilIfEmpty(Array.mapIndexes(function(mapIndex)
		local prefix = 'map' .. mapIndex
		if Logic.isEmpty(inputs[prefix]) then
			return
		end

		return self:_backFillMap{
			todo
		}
	end))

	assert(inputs.title or not requireTitle, 'Category is missing a title')
	return {maps = maps, title = inputs.title}
end

---@param args table
---@return {maps: StandardMap, title: string?}[]
function MapPoolTable._readFromInfobox(args)
end

---@param map table
---@return StandardMap
function MapPoolTable:_backFillMap(map)
end

--[[
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
]]

---@return Widget?
function MapPoolTable:display()
	if Logic.isEmpty(self.mapCategories) then
		return
	end

	todo
end

return MapPoolTable
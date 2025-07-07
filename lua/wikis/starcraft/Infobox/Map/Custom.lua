---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class StarcraftMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class StarcraftMapInfoboxWidgetInjector: WidgetInjector
---@field caller StarcraftMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param widgetId string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(widgetId, widgets)
	local args = self.caller.args
	local id = args.id

	if widgetId == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Tileset', content = {args.tileset or self.caller:_tlpdMap(id, 'tileset')}},
			Cell{name = 'Size', content = {self.caller:_getSize(id, args)}},
			Cell{name = 'Spawn Positions', content = {self.caller:_getSpawn(id, args)}},
			Cell{name = 'Versions', content = {String.convertWikiListToHtmlList(args.versions)}},
			Cell{name = 'Leagues Featured', content = {args.leagues}}
		)
	end

	return widgets
end

---@param args table
---@return string?
function CustomMap:getNameDisplay(args)
	if String.isEmpty(args.name) then
		return self:_tlpdMap(args.id, 'name')
	end

	return args.name
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.name = self:getNameDisplay(args)
	lpdbData.extradata.spawns = args.players
	lpdbData.extradata.height = args.height
	lpdbData.extradata.width = args.width
	return lpdbData
end

---@param id string?
---@param args table
---@return string
function CustomMap:_getSize(id, args)
	local width = args.width
		or self:_tlpdMap(id, 'width') or ''
	local height = args.height
		or self:_tlpdMap(id, 'height') or ''
	return width .. 'x' .. height
end

---@param id string?
---@param args table
---@return string
function CustomMap:_getSpawn(id, args)
	local players = args.players
		or self:_tlpdMap(id, 'players') or ''
	local positions = args.positions
		or self:_tlpdMap(id, 'positions') or ''
	return players .. ' at ' .. positions
end

---@param id string?
---@param query string
---@return string?
function CustomMap:_tlpdMap(id, query)
	if not id then return nil end
	return Template.safeExpand(mw.getCurrentFrame(), 'Tlpd map', {id, query})
end

---@param args table
---@return string[]
function CustomMap:getWikiCategories(args)
	local players = args.players or self:_tlpdMap(args.id, 'players')
	local tileset = args.tileset or self:_tlpdMap(args.id, 'tileset')

	return Array.append({},
		String.isNotEmpty(players) and ('Maps (' .. players .. ' Players)') or nil,
		String.isNotEmpty(tileset) and (tileset .. ' Tileset') or nil
	)
end

return CustomMap

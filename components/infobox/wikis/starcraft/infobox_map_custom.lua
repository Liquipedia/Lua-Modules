---
-- @Liquipedia
-- wiki=starcraft
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Map = Lua.import('Module:Infobox/Map', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class StarcraftMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	Array.appendWith(widgets,
		Cell{name = 'Tileset', content = {args.tileset or CustomMap:_tlpdMap(id, 'tileset')}},
		Cell{name = 'Size', content = {CustomMap:_getSize(id, args)}},
		Cell{name = 'Spawn Positions', content = {CustomMap:_getSpawn(id, args)}},
		Cell{name = 'Versions', content = {String.convertWikiListToHtmlList(args.versions)}},
		Cell{name = 'Competition Span', content = {args.span}},
		Cell{name = 'Leagues Featured', content = {args.leagues}}
	)

	return widgets
end

---@param args table
---@return string?
function CustomMap:getNameDisplay(args)
	if String.isEmpty(args.name) then
		return CustomMap:_tlpdMap(args.id, 'name')
	end

	return args.name
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.name = CustomMap:getNameDisplay(args)
	lpdbData.extradata = {
		creator = args.creator and mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator) or nil,
		spawns = args.players,
		height = args.height,
		width = args.width,
	}
	return lpdbData
end

---@param id string?
---@return string
function CustomMap:_getSize(id, args)
	local width = args.width
		or CustomMap:_tlpdMap(id, 'width') or ''
	local height = args.height
		or CustomMap:_tlpdMap(id, 'height') or ''
	return width .. 'x' .. height
end

---@param id string?
---@return string
function CustomMap:_getSpawn(id, args)
	local players = args.players
		or CustomMap:_tlpdMap(id, 'players') or ''
	local positions = args.positions
		or CustomMap:_tlpdMap(id, 'positions') or ''
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
	local players = args.players
	if String.isEmpty(players) then
		players = CustomMap:_tlpdMap(args.id, 'players')
	end

	if String.isEmpty(players) then
		return {}
	end

	return {'Maps (' .. players .. ' Players)'}
end

return CustomMap

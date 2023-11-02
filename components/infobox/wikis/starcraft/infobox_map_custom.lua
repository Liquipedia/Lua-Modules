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

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local customMap = Map(frame)

	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.getWikiCategories = CustomMap.getWikiCategories
	customMap.addToLpdb = CustomMap.addToLpdb

	_args = customMap.args
	return customMap:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	local id = _args.id

	Array.appendWith(widgets,
		Cell{name = 'Tileset', content = {_args.tileset or CustomMap:_tlpdMap(id, 'tileset')}},
		Cell{name = 'Size', content = {CustomMap:_getSize(id)}},
		Cell{name = 'Spawn Positions', content = {CustomMap:_getSpawn(id)}},
		Cell{name = 'Versions', content = {String.convertWikiListToHtmlList(_args.versions)}},
		Cell{name = 'Competition Span', content = {_args.span}},
		Cell{name = 'Leagues Featured', content = {_args.leagues}}
	)

	return widgets
end

---@return WidgetInjector
function CustomMap:createWidgetInjector()
	return CustomInjector()
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
function CustomMap:_getSize(id)
	local width = _args.width
		or CustomMap:_tlpdMap(id, 'width') or ''
	local height = _args.height
		or CustomMap:_tlpdMap(id, 'height') or ''
	return width .. 'x' .. height
end

---@param id string?
---@return string
function CustomMap:_getSpawn(id)
	local players = _args.players
		or CustomMap:_tlpdMap(id, 'players') or ''
	local positions = _args.positions
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

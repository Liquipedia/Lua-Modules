---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

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
	_args = customMap.args
	return customMap:createInfobox()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	local id = _args.id

	return Array.append(
		widgets,
		Cell{name = 'Tileset', content = {_args.tileset or CustomMap:_tlpdMap(id, 'tileset')}},
		Cell{name = 'Size', content = {CustomMap:_getSize(id)}},
		Cell{name = 'Spawn Positions', content = {CustomMap:_getSpawn(id)}},
		Cell{name = 'Versions', content = {_args.versions}},
		Cell{name = 'Competition Span', content = {_args.span}},
		Cell{name = 'Leagues Featured', content = {_args.leagues}},
		Cell{name = '[[Rush distance]]', content = {CustomMap:_getRushDistance()}},
		Cell{name = '1v1 Ladder', content = {_args['1v1history']}},
		Cell{name = '2v2 Ladder', content = {_args['2v2history']}},
		Cell{name = '3v3 Ladder', content = {_args['3v3history']}},
		Cell{name = '4v4 Ladder', content = {_args['4v4history']}}
	)
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
		creator = mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator),
		creator2 = mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator2),
		spawns = args.players,
		height = args.height,
		width = args.width,
		rush = Variables.varDefault('rush_distance'),
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

---@return string?
function CustomMap:_getRushDistance()
	if String.isEmpty(_args['rush_distance']) then
		return nil
	end
	local rushDistance = _args['rush_distance']
	rushDistance = string.gsub(rushDistance, 's', '')
	rushDistance = string.gsub(rushDistance, 'seconds', '')
	rushDistance = string.gsub(rushDistance, ' ', '')
	Variables.varDefine('rush_distance', rushDistance)
	return rushDistance .. ' seconds'
end

---@param id string?
---@param query string
---@return string?
function CustomMap:_tlpdMap(id, query)
	if not id then return nil end
	return Template.safeExpand(mw.getCurrentFrame(), 'Tlpd map', { id, query })
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

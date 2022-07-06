---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Map = require('Module:Infobox/Map')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local String = require('Module:StringUtils')

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.getCategories = CustomMap.getCategories
	_args = customMap.args
	return customMap:createInfobox(frame)
end

function CustomInjector:addCustomCells(widgets)
	local id = _args.id

	table.insert(widgets, Cell{
		name = 'Tileset',
		content = {
			_args.tileset or CustomMap:_tlpdMap(id, 'tileset')
		}
	})
	table.insert(widgets, Cell{
		name = 'Size',
		content = {CustomMap:_getSize(id)}
	})
	table.insert(widgets, Cell{
		name = 'Spawn Positions',
		content = {CustomMap:_getSpawn(id)}
	})
	table.insert(widgets, Cell{
		name = 'Versions',
		content = {_args.versions}
	})
	table.insert(widgets, Cell{
		name = 'Competition Span',
		content = {_args.span}
	})
	table.insert(widgets, Cell{
		name = 'Leagues Featured',
		content = {_args.leagues}
	})
	table.insert(widgets, Cell{
		name = '[[Rush distance]]',
		content = {CustomMap:_getRushDistance()}
	})
	table.insert(widgets, Cell{
		name = '1v1 Ladder',
		content = {_args['1v1history']}
	})
	table.insert(widgets, Cell{
		name = '2v2 Ladder',
		content = {_args['2v2history']}
	})
	table.insert(widgets, Cell{
		name = '3v3 Ladder',
		content = {_args['3v3history']}
	})
	table.insert(widgets, Cell{
		name = '4v4 Ladder',
		content = {_args['4v4history']}
	})

	return widgets
end

function CustomMap:createWidgetInjector()
	return CustomInjector()
end

function CustomMap:getNameDisplay(args)
	if String.isEmpty(args.name) then
		return CustomMap:_tlpdMap(args.id, 'name')
	end

	return args.name
end

function CustomMap:addToLpdb(lpdbData)
	lpdbData.name = CustomMap:getNameDisplay(_args)
	lpdbData.extradata = {
		creator = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator),
		creator2 = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator2),
		spawns = _args.players,
		height = _args.height,
		width = _args.width,
		rush = Variables.varDefault('rush_distance'),
	}
	return lpdbData
end

function CustomMap:_getSize(id)
	local width = _args.width
		or CustomMap:_tlpdMap(id, 'width') or ''
	local height = _args.height
		or CustomMap:_tlpdMap(id, 'height') or ''
	return width .. 'x' .. height
end

function CustomMap:_getSpawn(id)
	local players = _args.players
		or CustomMap:_tlpdMap(id, 'players') or ''
	local positions = _args.positions
		or CustomMap:_tlpdMap(id, 'positions') or ''
	return players .. ' at ' .. positions
end

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

function CustomMap:_tlpdMap(id, query)
	if not id then return nil end
	return Template.safeExpand(mw.getCurrentFrame(), 'Tlpd map', { id, query })
end

return CustomMap

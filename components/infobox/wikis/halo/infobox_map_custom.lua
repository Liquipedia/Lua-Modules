---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Map
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Map = require('Module:Infobox/Map')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local MapModes = require('Module:MapModes')

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _game

local _GAME = mw.loadData('Module:GameVersion')

function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.getCategories = CustomMap.getCategories
	_args = customMap.args
	return customMap:createInfobox(frame)
end

function CustomMap:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	table.insert(widgets, Cell{
		name = 'Location',
		content = {_args.location}
	})
	table.insert(widgets, Cell{
		name = 'Type',
		content = {_args.type}
	})
	table.insert(widgets, Cell{
		name = 'Game Version',
		content = {CustomMap._getGameVersion()},
		options = {makeLink = true}
	})
	table.insert(widgets, Cell{
		name = 'Game Modes',
		content = {CustomMap._getGameMode(_args.mode)}
	})
	return widgets
end

function CustomMap._getGameVersion()
	local game = string.lower(_args.game or '')
	_game = _GAME[game]
	return _game
end

function CustomMap._getGameMode()
	local modeIcon = MapModes.get({mode = _args.mode, date = _args.releasedate, size = 15})
	local mapModeDisplay = modeIcon .. " [[".._args.mode.."|".._args.mode.."]]"
	return mapModeDisplay
end

function CustomMap:createWidgetInjector()
	return CustomInjector()
end

function CustomMap:addToLpdb(lpdbData)
	lpdbData.extradata.creator2 = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator2)
	lpdbData.extradata.type = _args.type
	lpdbData.extradata.game = _game
	lpdbData.extradata.modes = _args.mode
	return lpdbData
end

return CustomMap

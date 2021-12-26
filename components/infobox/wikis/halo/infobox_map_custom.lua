---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Map
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Map = require('Module:Infobox/Map')
local Widgets = require('Module:Infobox/Widget/All')
local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')
local Template = require('Module:Template')
local Variables = require('Module:Variables')
local String = require('Module:StringUtils')
local MapModes = require('Module:MapModes')

local Customizable = Widgets.Customizable
local Builder = Widgets.Builder
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
	--[[table.insert(widgets, Cell{
		name = 'Game',
		content = {_args.game},
		options = { makeLink = true }
	})]]
	table.insert(widgets, Cell{
		name = 'Release Date',
		content = {_args.releasedate}
	})
	table.insert(widgets, Cell{
		name = 'Location',
		content = {_args.location}
	})
	table.insert(widgets, Cell{
		name = 'Type',
		content = {_args.type} --{CustomMap:_getType(id)}
	})
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'gamesettings' then
		return {
			Cell{name = 'Game version', content = {
					CustomMap._getGameVersion()
				}},
			}
	end
	return widgets
end

function CustomMap._getGameVersion()
	local game = string.lower(_args.game or '')
	_game = _GAME[game]
	return _game
end

function CustomMap:createWidgetInjector()
	return CustomInjector()
end

function CustomMap:addToLpdb(lpdbData)
	lpdbData.extradata = {
		creator = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator),
		creator2 = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator2),
		releasedate = _args.release_date,
		type = _args.type,
	}
	return lpdbData
end

return CustomMap

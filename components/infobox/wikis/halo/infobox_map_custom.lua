---
-- @Liquipedia
-- wiki=halo
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')
local String = require('Module:StringUtils')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Map = Lua.import('Module:Infobox/Map', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _game

local _GAME = mw.loadData('Module:GameVersion')

function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.getCategories = CustomMap.getCategories
	customMap.addToLpdb = CustomMap.addToLpdb
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
		name = 'Max Players',
		content = {_args.players}
	})
	table.insert(widgets, Cell{
		name = 'Game Version',
		content = {CustomMap._getGameVersion()},
		options = {makeLink = true}
	})
	table.insert(widgets, Cell{
		name = 'Game Modes',
		content = CustomMap._getGameMode(),
	})
	return widgets
end

function CustomMap._getGameVersion()
	local game = string.lower(_args.game or '')
	_game = _GAME[game]
	return _game
end

function CustomMap._getGameMode()
	if String.isEmpty(_args.mode) and String.isEmpty(_args.mode1) then
		return {}
	end

	local modes = Map:getAllArgsForBase(_args, 'mode')
	local releasedate = _args.releasedate

	local modeDisplayTable = {}
	for _, mode in ipairs(modes) do
		local modeIcon = MapModes.get({mode = mode, date = releasedate, size = 15})
		local mapModeDisplay = modeIcon .. ' [[' .. mode .. ']]'
		table.insert(modeDisplayTable, mapModeDisplay)
	end

	return modeDisplayTable
end

function CustomMap:addToLpdb(lpdbData)
	lpdbData.extradata.creator = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator)
	if String.isNotEmpty(_args.creator2) then
		lpdbData.extradata.creator2 = mw.ext.TeamLiquidIntegration.resolve_redirect(_args.creator2)
	end
	lpdbData.extradata.type = _args.type
	lpdbData.extradata.players = _args.players
	lpdbData.extradata.game = _game
	lpdbData.extradata.modes = table.concat(Map:getAllArgsForBase(_args, 'mode'), ',')
	return lpdbData
end

return CustomMap

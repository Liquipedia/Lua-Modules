---
-- @Liquipedia
-- wiki=overwatch
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
local Flags = Lua.import('Module:Flags', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomMap = Class.new()

local CustomInjector = Class.new(Injector)

local _args

function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.addToLpdb = CustomMap.addToLpdb
	_args = customMap.args
	return customMap:createInfobox(frame)
end

function CustomMap:createWidgetInjector()
	return CustomInjector()
end

function CustomInjector:addCustomCells(widgets)
	local gameModes = CustomMap._getGameMode()
	table.insert(widgets, Cell{
		name = #gameModes == 1 and 'Game Mode' or 'Game Modes',
        content = gameModes,
	})
	table.insert(widgets, Cell{
		name = 'Checkpoints',
		content = {_args.checkpoints}
	})
	return widgets
end

function CustomInjector:parse(id, widgets)
	if id == 'location' then
		return {
			Cell{
				name = 'Location',
				content = {Flags.Icon{flag = _args.location, shouldLink = false} .. '&nbsp;' .. _args.location}
			},
		}
	end
	return widgets
end

function CustomMap._getGameMode()
	if String.isEmpty(_args.mode) and String.isEmpty(_args.mode1) then
		return {}
	end

	local modes = Map:getAllArgsForBase(_args, 'mode')
	local releaseDate = _args.releasedate

	local modeDisplayTable = {}
	for _, mode in ipairs(modes) do
		local modeIcon = MapModes.get({mode = mode, date = releaseDate, size = 15})
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
	lpdbData.extradata.modes = table.concat(Map:getAllArgsForBase(_args, 'mode'), ',')
	return lpdbData
end

return CustomMap

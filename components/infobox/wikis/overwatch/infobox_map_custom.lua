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

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local customMap = Map(frame)
	customMap.createWidgetInjector = CustomMap.createWidgetInjector
	customMap.addToLpdb = CustomMap.addToLpdb
	_args = customMap.args
	return customMap:createInfobox()
end

---@return WidgetInjector
function CustomMap:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	local gameModes = CustomMap._getGameMode()
	table.insert(widgets, Cell{
		name = #gameModes == 1 and 'Game Mode' or 'Game Modes',
		content = gameModes,
	})
	table.insert(widgets, Cell{
		name = 'Lighting',
		content = {_args.lighting}
	})
	table.insert(widgets, Cell{
		name = 'Checkpoints',
		content = {_args.checkpoints}
	})
	return widgets
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
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

---@return string[]
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

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.creator = mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator)
	if String.isNotEmpty(args.creator2) then
		lpdbData.extradata.creator2 = mw.ext.TeamLiquidIntegration.resolve_redirect(args.creator2)
	end
	lpdbData.extradata.modes = table.concat(Map:getAllArgsForBase(args, 'mode'), ',')
	return lpdbData
end

return CustomMap

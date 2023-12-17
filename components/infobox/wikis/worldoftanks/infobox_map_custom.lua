---
-- @Liquipedia
-- wiki=worldoftanks
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
	customMap.getWikiCategories = CustomMap.getWikiCategories
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
	table.insert(widgets, Cell{
		name = 'Map Season',
		content = {_args.season}
	})
	table.insert(widgets, Cell{
		name = 'Size',
		content = {(_args.width or '') .. 'x' .. (_args.height or '')}
	})
	table.insert(widgets, Cell{
		name = 'Battle Tier',
		content = {(_args.btmin or '') .. '-' .. (_args.btmax or '')}
	})
	table.insert(widgets, Cell{
		name = 'Game Modes',
		content = CustomMap._getGameMode(),
	})
	return widgets
end

---@return string[]
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

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.width = args.width
	lpdbData.extradata.height = args.height
	lpdbData.extradata.battletierminimum = args.btmin
	lpdbData.extradata.battletiermaximum = args.btmax
	lpdbData.extradata.season = args.season
	lpdbData.extradata.modes = table.concat(Map:getAllArgsForBase(args, 'mode'), ',')
	mw.log(lpdbData)
	return lpdbData
end

---@param args table
---@return categories
function CustomMap:getWikiCategories(args)
	return {
    --[TODO: Fix this method so it properly creates the categories
		--[[CustomMap.season{season = args.season} .. ' Maps',
		CustomMap.location{location = args.location} .. ' Maps',]]--
	}
end

return CustomMap

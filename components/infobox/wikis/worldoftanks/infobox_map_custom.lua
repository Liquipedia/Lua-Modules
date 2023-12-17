---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
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
	return Array.append(widgets,
		Cell{name = 'Map Season', content = {_args.season}},
		Cell{name = 'Size', content = {(_args.width or '') .. 'x' .. (_args.height or '')}},
		Cell{name = 'Battle Tier', content = {(_args.btmin or '') .. '-' .. (_args.btmax or '')}},
		Cell{name = 'Game Modes', content = CustomMap._getGameMode()}
	)
end

---@return string[]
function CustomMap._getGameMode()
	if String.isEmpty(_args.mode) and String.isEmpty(_args.mode1) then
		return {}
	end

	local modes = Map:getAllArgsForBase(_args, 'mode')
	local releasedate = _args.releasedate

	return Array.map(modes, function(mode)
		local modeIcon = MapModes.get{mode = mode, date = releasedate, size = 15}
		return modeIcon .. ' [[' .. mode .. ']]'
	end)
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
	lpdbData.extradata = Table.merge(lpdbData.extradata, {
		args.width,
		args.height
	})
	lpdbData.extradata = Table.merge(lpdbData.extradata, {
		args.btmin,
		args.btmax
	})
	lpdbData.extradata.season = args.season
	lpdbData.extradata.modes = table.concat(Map:getAllArgsForBase(args, 'mode'), ',')
	return lpdbData
end

function CustomMap:getWikiCategories(args)
	return {
		--[[CustomMap.season{season = args.season} .. ' Maps',
		CustomMap.location{location = args.location} .. ' Maps',]]--
	}
end

return CustomMap

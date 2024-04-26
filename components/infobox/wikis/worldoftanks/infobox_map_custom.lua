---
-- @Liquipedia
-- wiki=worldoftanks
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')
local Flags = Lua.import('Module:Flags')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class WorldoftanksMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'location' and String.isNotEmpty(args.location) then
		return {
			Cell{
				name = 'Location',
				content = {Flags.Icon{flag = args.location, shouldLink = false} .. '&nbsp;' .. args.location}
			},
		}
	elseif id == 'custom' then
		return Array.append(widgets,
			Cell{name = 'Map Season', content = {args.season}},
			Cell{name = 'Size', content = {(args.width or '') .. ' x ' .. (args.height or '')}},
			Cell{name = 'Battle Tier', content = {String.isNotEmpty(args.btmin) and
				String.isNotEmpty(args.btmax) and (args.btmin .. ' - ' .. args.btmax) or nil}
			},
			Cell{name = 'Game Modes', content = self.caller:_getGameMode(args)}
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomMap:_getGameMode(args)
	if String.isEmpty(args.mode) and String.isEmpty(args.mode1) then
		return {}
	end

	local modes = self:getAllArgsForBase(args, 'mode')
	local releasedate = args.releasedate

	return Array.map(modes, function(mode)
		local modeIcon = MapModes.get{mode = mode, date = releasedate, size = 15}
		return modeIcon .. ' [[' .. mode .. ']]'
	end)
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata = Table.merge(lpdbData.extradata, {
		location = args.location,
		width = args.width,
		height = args.height,
		battletiermin = args.btmin,
		battletiermax = args.btmax,
		season = args.season,
		modes = Json.stringify(self:getAllArgsForBase(args, 'mode'))
	})

	return lpdbData
end

---@param args table
---@return table
function CustomMap:getWikiCategories(args)
	local categories = {}
	if String.isNotEmpty(args.season) then
		table.insert(categories, args.season .. ' Maps')
	end
	if String.isNotEmpty(args.location) then
		table.insert(categories, 'Maps located in ' .. args.location)
	end

	return categories
end

return CustomMap

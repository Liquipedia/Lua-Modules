---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MapModes = Lua.import('Module:MapModes')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')
local Flags = Lua.import('Module:Flags')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class WorldoftanksMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class WorldoftanksMapInfoboxWidgetInjector: WidgetInjector
---@field caller WorldoftanksMapInfobox
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
			Cell{
				name = 'Game Modes',
				content = Array.map(
					self.caller:getGameModes(args),
					function (gameMode)
						local modeIcon = MapModes.get{mode = gameMode, date = args.releasedate, size = 15}
						return modeIcon .. ' [[' .. gameMode .. ']]'
					end
				)
			}
		)
	end
	return widgets
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

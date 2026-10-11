---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

---@class DeltaforceMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class DeltaforceMapInfoboxWidgetInjector: WidgetInjector
---@field caller DeltaforceMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param widgetId string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(widgetId, widgets)
	local args = self.caller.args

	if widgetId == 'custom' then
	local gameModes = self.caller:getGameModes(args)
		return Array.append(
			widgets,
			Cell{name = #gameModes == 1 and 'Game Mode' or 'Game Modes', children = gameModes},
			Cell{name = 'Map Type', children = {args.type}}
		)
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.type = args.type
	return lpdbData
end

return CustomMap

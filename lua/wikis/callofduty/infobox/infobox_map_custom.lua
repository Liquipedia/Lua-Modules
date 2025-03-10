---
-- @Liquipedia
-- wiki=callofduty
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Game = Lua.import('Module:Game')
local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class CallofdutyMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
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
		return Array.append(
			widgets,
			Cell{name = 'Type', content = {args.type}},
			Cell{name = 'Size', content = {args.size}},
			Cell{name = 'Game Version', content = {Game.name{game = args.game}}, options = {makeLink = true}},
			Cell{name = 'Day/Night Variant', content = {args.daynight}},
			Cell{name = 'Playlists', content = {args.playlist}}
		)
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomMap:addToLpdb(lpdbData, args)
	lpdbData.extradata.type = args.type
	lpdbData.extradata.size = args.size
	lpdbData.extradata.game = Game.name{game = args.game}
	lpdbData.extradata.daynight = args.daynight
	lpdbData.extradata.playlist = args.playlist
	return lpdbData
end

return CustomMap

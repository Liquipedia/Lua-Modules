---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Game = Lua.import('Module:Game')
local Table = Lua.import('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = Lua.import('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

---@class CallofdutyMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class CallofdutyMapInfoboxWidgetInjector: WidgetInjector
---@field caller CallofdutyMapInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomMap.run(frame)
	local map = CustomMap(frame)
	map:setWidgetInjector(CustomInjector(map))

	return map:createInfobox()
end

---@param args table
---@return string[]
function CustomMap:_getGames(args)
	return Array.map(self:getAllArgsForBase(args, 'game'), function(game) return Game.name{game = game} end)
end

---@param widgetId string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(widgetId, widgets)
	local args = self.caller.args

	if widgetId == 'custom' then
		local games = self.caller:_getGames(args)
		return Array.append(
			widgets,
			Cell{name = 'Type', content = {args.type}},
			Cell{name = #games > 1 and 'Game Versions' or 'Game Version', content = games, options = {makeLink = true}},
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
	Table.mergeInto(lpdbData.extradata, Table.map(self:_getGames(args), function(gameIndex, game)
		return 'game' .. gameIndex, game
	end))
	lpdbData.extradata.daynight = args.daynight
	lpdbData.extradata.playlist = args.playlist
	return lpdbData
end

return CustomMap

---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class RocketLeagueMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class RocketLeagueMapInfoboxWidgetInjector: WidgetInjector
---@field caller RocketLeagueMapInfobox
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

	if id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Layout', content = {args.layout}},
			Cell{name = 'Versions', content = {args.versions}},
			Cell{name = 'Playlists', content = {args.playlists}},
			Cell{name = 'Gamemodes', content = self.caller:getGameModes(args)}
		)
	end
	return widgets
end

---@param args table
---@return string[]
function CustomMap:getGameModes(args)
	return Array.parseCommaSeparatedString(args.gamemodes)
end

return CustomMap

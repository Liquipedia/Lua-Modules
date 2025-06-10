---
-- @Liquipedia
-- wiki=rainbowsix
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

---@class RainbowsixMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class RainbowsixMapInfoboxWidgetInjector: WidgetInjector
---@field caller RainbowsixMapInfobox
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
		return Array.append(
			widgets,
			Cell{name = 'Game', content = {args.game}},
			Cell{name = 'Released', content = {args.released}},
			Cell{name = 'Size', content = {args.size}},
			Cell{name = 'Map Buff', content = {args.buff}},
			Cell{name = 'Theme', content = {args.theme}},
			Cell{name = 'Playlists', content = {args.playlists}}
		)
	end

	return widgets
end

return CustomMap

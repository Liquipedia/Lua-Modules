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
local Flags = Lua.import('Module:Flags')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class ValorantMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class ValorantMapInfoboxWidgetInjector: WidgetInjector
---@field caller ValorantMapInfobox
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

	if id == 'location' then
		return {
			Cell{
				name = 'Location',
				content = {
					args.country and (Flags.Icon{flag = args.country, shouldLink = false} .. '&nbsp;' .. args.country)
					or nil
				},
			},
		}
	elseif id == 'custom' then
		Array.appendWith(
			widgets,
			Cell{name = 'Bomb Sites', content = {args.bombsites}},
			Cell{name = 'Teleporters', content = {args.teleporters}},
			Cell{name = 'Game Mode', content = self.caller:getGameModes(args)}
		)
	end
	return widgets
end

return CustomMap

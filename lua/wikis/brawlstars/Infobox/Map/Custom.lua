---
-- @Liquipedia
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local ModeIcon = require('Module:ModeIcon')

local Injector = Lua.import('Module:Widget/Injector')
local Map = Lua.import('Module:Infobox/Map')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class BrawlstarsMapInfobox: MapInfobox
local CustomMap = Class.new(Map)
---@class BrawlstarsMapInfoboxWidgetInjector: WidgetInjector
---@field caller BrawlstarsMapInfobox
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
		local modes = self.caller:getGameModes(args)
		Array.appendWith(widgets,
			Cell{name = 'Environment', content = {args.environment}},
			Title{children = modes and 'Mode' or nil},
			Center{
				children = modes and Array.interleave(
					Array.map(modes, ModeIcon.run),
					'<br>'
				) or nil
			}
		)
	end
	return widgets
end

return CustomMap

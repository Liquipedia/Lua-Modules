---
-- @Liquipedia
-- wiki=brawlstars
-- page=Module:Infobox/Map/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local ModeIcon = require('Module:ModeIcon')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Map = Lua.import('Module:Infobox/Map', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class BrawlstarsMapInfobox: MapInfobox
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
	local modes = self.caller:getModes(args)

	Array.appendWith(widgets,
		Cell{name = 'Environment', content = {args.environment}},
		Title{name = modes and 'Mode' or nil},
		Center{content = modes and {table.concat(modes, '<br>')} or nil}
	)

	return widgets
end

---@param args table
---@return string[]?
function CustomMap:getModes(args)
	local modes = self:getAllArgsForBase(args, 'mode')

	if Table.isEmpty(modes) then return end

	return Array.map(modes, ModeIcon.run)
end

return CustomMap

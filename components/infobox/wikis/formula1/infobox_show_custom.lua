---
-- @Liquipedia
-- wiki=formula1
-- page=Module:Infobox/Show/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Injector = Lua.import('Module:Infobox/Widget/Injector', {requireDevIfEnabled = true})
local Show = Lua.import('Module:Infobox/Show', {requireDevIfEnabled = true})

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell

local CustomShow = Class.new()
local CustomInjector = Class.new(Injector)

local _args

---@param frame Frame
---@return Html
function CustomShow.run(frame)
	local show = show(frame)
	_args = show.args

	show.addToLpdb = CustomShow.addToLpdb
	show.createWidgetInjector = CustomShow.createWidgetInjector

	return show:createInfobox()
end

---@return WidgetInjector
function CustomShow:createWidgetInjector()
	return CustomInjector()
end

---@param widgets Widget[]
---@return Widget[]
function CustomInjector:addCustomCells(widgets)
	return Array.appendWith(widgets,
		Cell{name = 'Type', content = {_args.type}},
		Cell{name = 'Host', content = {_args.host}},
		Cell{name = 'Location', content = {_args.location}}	
	)
end

return Show

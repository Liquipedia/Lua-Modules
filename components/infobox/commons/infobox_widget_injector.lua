---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Injector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

---@class WidgetInjector
local Injector = Class.new()

---Parses the widgets
---@param id string
---@param widgets Widget[]
---@return Widget[]?
function Injector:parse(id, widgets)
	return widgets
end

---Adds custom cells
---@param widgets Widget[]
---@return Widget[]?
function Injector:addCustomCells(widgets)
	return {}
end

return Injector


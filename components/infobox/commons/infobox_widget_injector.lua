---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Widget/Injector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

---@class WidgetInjector
---@operator call(table?): WidgetInjector
---@field caller table?
local Injector = Class.new(
	---@param self self
	---@param caller table?
	function(self, caller)
		self.caller = caller
end)

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

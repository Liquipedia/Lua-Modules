---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Injector
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

---@class WidgetInjector: BaseClass
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

return Injector

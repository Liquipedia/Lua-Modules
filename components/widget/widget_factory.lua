---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')

---@class WidgetFactory
local WidgetFactory = Class.new()

---@param widget Widget
---@param injector WidgetInjector?
---@return string
function WidgetFactory.work(widget, injector)
	local children = widget:tryMake(injector)

	if not children then
		return ''
	end

	if type(children) == 'string' then
		return children
	end

	return table.concat(Array.map(children, function(child)
		return WidgetFactory.work(child, injector)
	end))
end

return WidgetFactory

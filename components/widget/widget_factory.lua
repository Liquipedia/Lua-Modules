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
---@return Html
function WidgetFactory.work(widget, injector)
	local children = widget:tryMake(injector)

	if not children then
		return mw.html.create()
	end

	if Array.isArray(children) then
		---@cast children Widget[]
		local wrapper = mw.html.create()
		Array.forEach(children, function(child)
			wrapper:node(WidgetFactory.work(child, injector))
		end)
		return wrapper
	end

	---@cast children Html
	return children
end

return WidgetFactory

---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')

local WidgetFactory = {}

---@param args {widget: string, children: ((Widget|Html|string|number)[])|Widget|Html|string|number, [any]:any}
---@return Widget
function WidgetFactory.fromTemplate(args)
	local widgetClass = args.widget
	args.widget = nil
	args.children = type(args.children) == 'table' and args.children or {args.children}
	local WidgetClass = require('Module:Widget/' .. widgetClass)
	return WidgetClass(args)
end

return Class.export(WidgetFactory)

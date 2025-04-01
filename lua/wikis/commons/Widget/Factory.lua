---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Factory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local WidgetFactory = {}

---@param args {widget: string, children: ((Widget|Html|string|number)[])|Widget|Html|string|number, [any]:any}
---@return Widget
function WidgetFactory.fromTemplate(args)
	local widgetClass = args.widget
	args.widget = nil
	args.children = type(args.children) == 'table' and args.children or {args.children}
	local WidgetClass = Lua.import('Module:Widget/' .. widgetClass)
	return WidgetClass(args)
end

---@param widget string|Widget
---@param props table
---@param ... (Widget|Html|string|number)
function WidgetFactory.createElement(widget, props, ...)
	local widgetClass = widget
	if type(widget) == 'string' then
		widgetClass = HtmlWidgets[widget]
	end

	assert(widgetClass, 'Widget not found')

	return widgetClass(Table.merge(props, {children = WidgetUtil.collect(...)}))
end

return Class.export(WidgetFactory)

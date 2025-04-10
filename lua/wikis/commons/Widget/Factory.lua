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
	local Widget = Lua.import('Module:Widget')
	local widgetClass = args.widget
	assert(args.widget, '|widget= is required')
	args.widget = nil
	args.children = type(args.children) == 'table' and args.children or {args.children}
	local WidgetClass = Lua.import('Module:Widget/' .. widgetClass)
	assert(WidgetClass, 'Widget not found: ' .. widgetClass)
	if not Class.instanceOf(WidgetClass, Widget) then
		WidgetClass = WidgetClass.default
		assert(type(WidgetClass) == 'function', 'Widget not found: ' .. widgetClass)
	end
	return WidgetClass(args)
end

---@param widget string|Widget|fun(props: table?):Widget
---@param props table?
---@param ... (Widget|Html|string|number)
---@return Widget
function WidgetFactory.createElement(widget, props, ...)
	props = props or {}
	local widgetClass = widget
	if type(widget) == 'string' then
		widget = (widget:gsub("^%l", string.upper))
		props.new = true
		widgetClass = HtmlWidgets[widget]
	end

	assert(widgetClass, 'Widget not found')

	return widgetClass(Table.merge(props, {children = WidgetUtil.collect(...)}))
end

return Class.export(WidgetFactory)

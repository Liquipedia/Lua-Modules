---
-- @Liquipedia
-- page=Module:Widget/GeneralCollapsible/Default
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local CollapsibleToggle = Lua.import('Module:Widget/GeneralCollapsible/Toggle')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local B = HtmlWidgets.B
local Div = HtmlWidgets.Div
local Widget = Lua.import('Module:Widget')

---@class DefaultCollapsibleProps
---@field attributes table<string, string>?
---@field classes string[]?
---@field css table<string, string|number>?
---@field shouldCollapse boolean?
---@field title Renderable?
---@field titleClasses string[]?
---@field titleWidget Renderable?
---@field collapseAreaClasses string[]?
---@field children Renderable|Renderable[]?

---@class DefaultCollapsible: Widget
---@operator call(DefaultCollapsibleProps?): DefaultCollapsible
---@field props DefaultCollapsibleProps
local DefaultCollapsible = Class.new(Widget)

---@return Widget
function DefaultCollapsible:render()
	local props = self.props
	return Div{
		attributes = props.attributes,
		css = props.css,
		classes = Array.extend({},
			'general-collapsible',
			props.shouldCollapse and 'collapsed' or nil,
			props.classes
		),
		children = {
			props.titleWidget or Div{
				classes = Array.extend({'general-collapsible-default-header'}, props.titleClasses),
				children = {
					B{children = {props.title}, classes = {'general-collapsible-default-title'}},
					CollapsibleToggle{css = {float = 'right'}},
				}
			},
			Div{
				children = props.children,
				classes = Array.extend({},
					'should-collapse',
					props.collapseAreaClasses
				),
			},
		}
	}
end

return DefaultCollapsible

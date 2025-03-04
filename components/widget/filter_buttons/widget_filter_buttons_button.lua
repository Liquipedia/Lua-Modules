---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/FilterButtons/Button
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class FilterButton: Widget
---@operator call(table): FilterButton
---@field props {buttonClasses: string[]?, css: table<string,string>?, active: boolean?, value: string?, display: string|Widget|Html|nil}
local FilterButton = Class.new(Widget)

---@return Widget
function FilterButton:render()
	return HtmlWidgets.Span{
		classes = Array.extend({
			'filter-button',
			Logic.readBool(self.props.active) and 'filter-button--active' or nil
		}, self.props.buttonClasses),
		attributes = { ['data-filter-on'] = self.props.value },
		css = self.props.css,
		children = { self.props.display }
	}
end

return FilterButton

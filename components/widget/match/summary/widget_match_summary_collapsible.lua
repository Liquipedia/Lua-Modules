---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Collapsible
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Div = HtmlWidgets.Div
local TableWidget = HtmlWidgets.Table

---@class MatchSummaryCollapsible: Widget
---@operator call(table): MatchSummaryCollapsible
local MatchSummaryCollapsible = Class.new(Widget)
MatchSummaryCollapsible.defaultProps = {
	classes = {},
	tableCss = {},
}

---@return Widget
function MatchSummaryCollapsible:render()
	assert(self.props.header, 'No header supplied to MatchSummaryCollapsible Widget')

	return Div{
		classes = {'brkts-popup-mapveto', unpack(self.props.classes)},
		css = Table.merge({width = '100%'}, self.props.css),
		children = {
			TableWidget{
				classes = {'collapsible', 'collapsed', unpack(self.props.tableClasses)},
				css = self.props.tableCss,
				children = WidgetUtil.collect(
					self.props.header,
					unpack(self.props.children)
				)
			},
		},
	}
end

return MatchSummaryCollapsible

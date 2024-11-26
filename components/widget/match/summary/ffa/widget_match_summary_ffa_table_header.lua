---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/TableHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryFfaTableHeader: Widget
---@operator call(table): MatchSummaryFfaTableHeader
local MatchSummaryFfaTableHeader = Class.new(Widget)

---@return Widget
function MatchSummaryFfaTableHeader:render()
	return HtmlWidgets.div{
		classes = {'panel-table__row', 'row--header	'},
		attributes = {
			['data-js-battle-royale'] = 'header-row'
		},
		children = {self.props.children}
	}
end

return MatchSummaryFfaTableHeader

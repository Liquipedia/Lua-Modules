---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/TableRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryFfaTableRow: Widget
---@operator call(table): MatchSummaryFfaTableRow
local MatchSummaryFfaTableRow = Class.new(Widget)

---@return Widget
function MatchSummaryFfaTableRow:render()
	return HtmlWidgets.Div{
		classes = {'panel-table__row'},
		attributes = {
			['data-js-battle-royale'] = 'row'
		},
		children = self.props.children
	}
end

return MatchSummaryFfaTableRow

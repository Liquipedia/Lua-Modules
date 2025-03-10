---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/TableRowCell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryFfaTableRowCell: Widget
---@operator call(table): MatchSummaryFfaTableRowCell
local MatchSummaryFfaTableRowCell = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaTableRowCell:render()
	local isSortable = self.props.sortable

	return HtmlWidgets.Div{
		classes = {'panel-table__cell', self.props.class},
		attributes = {
			['data-sort-type'] = isSortable and self.props.sortType or nil,
			['data-sort-val'] = isSortable and self.props.sortValue or nil,
		},
		children = {
			HtmlWidgets.Div{
				classes = {'panel-table__cell-grouped'},
				children = self.props.value
			}
		}
	}
end

return MatchSummaryFfaTableRowCell

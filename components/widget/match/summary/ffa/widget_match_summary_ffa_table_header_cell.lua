---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/TableHeaderCell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class MatchSummaryFfaTableHeaderCell: Widget
---@operator call(table): MatchSummaryFfaTableHeaderCell
local MatchSummaryFfaTableHeaderCell = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaTableHeaderCell:render()
	if self.props.show and not self.props.show(match) then
		return
	end

	local isSortable = self.props.sortable

	return HtmlWidgets.Div{
		classes = {'panel-table__cell', self.props.class},
		children = {
			HtmlWidgets.Div{
				classes = {'panel-table__cell-grouped'},
				attributes = {
					['data-sort-type'] = isSortable and self.props.sortType or nil,
				},
				children = WidgetUtil.collect(
					HtmlWidgets.I{ -- TODO
						classes = {'panel-table__cell-icon', self.props.iconClass}
					},
					HtmlWidgets.Span{
						classes = {self.props.mobileValue and 'd-none d-md-block' or nil},
						children = self.props.value
					},
					self.props.mobileValue and HtmlWidgets.Span{
						classes = {'d-block d-md-none'},
						children = self.props.mobileValue
					} or nil,
					isSortable and HtmlWidgets.Div{
						classes = {'panel-table__sort'},
						children = {
							-- TOOO
							HtmlWidgets.I{
								classes = {'far fa-arrows-alt-v'},
								attributes = {
									['data-js-battle-royale'] = 'sort-icon'
								}
							}
						}
					} or nil
				)
			}
		}
	}
end

return MatchSummaryFfaTableHeaderCell

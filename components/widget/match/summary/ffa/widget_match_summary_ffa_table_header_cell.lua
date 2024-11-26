---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/TableHeaderCell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local WidgetUtil = Lua.import('Module:Widget/Util')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class MatchSummaryFfaTableHeaderCell: Widget
---@operator call(table): MatchSummaryFfaTableHeaderCell
local MatchSummaryFfaTableHeaderCell = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaTableHeaderCell:render()
	local isSortable = self.props.sortable

	return HtmlWidgets.Div{
		classes = {'panel-table__cell', self.props.class},
		attributes = {
			['data-sort-type'] = isSortable and self.props.sortType or nil,
		},
		children = {
			HtmlWidgets.Div{
				classes = {'panel-table__cell-grouped'},
				children = WidgetUtil.collect(
					self.props.icon and IconWidget{
						iconName = self.props.icon,
						additionalClasses = {'panel-table__cell-icon'}
					} or nil,
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
							IconWidget{
								iconName = 'sort',
								attributes = {
									['data-js-battle-royale'] = 'sort-icon'
								}
							},
						}
					} or nil
				)
			}
		}
	}
end

return MatchSummaryFfaTableHeaderCell

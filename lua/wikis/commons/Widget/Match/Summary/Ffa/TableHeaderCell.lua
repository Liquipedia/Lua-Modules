---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/TableHeaderCell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local IconWidget = Lua.import('Module:Widget/Image/Icon/Fontawesome')

---@class MatchSummaryFfaTableHeaderCellProps
---@field class? string
---@field sortType? string
---@field sortable? boolean
---@field icon? string
---@field mobileValue? Renderable|Renderable[]
---@field value? Renderable|Renderable[]

---@param props MatchSummaryFfaTableHeaderCellProps
---@return HtmlNode
local function MatchSummaryFfaTableHeaderCell(props)
	local isSortable = props.sortable

	return Html.Div{
		classes = {'panel-table__cell', props.class},
		attributes = {
			['data-sort-type'] = isSortable and props.sortType or nil,
		},
		children = Html.Div{
			classes = {'panel-table__cell-grouped'},
			children = WidgetUtil.collect(
				props.icon and IconWidget{
					iconName = props.icon,
					additionalClasses = {'panel-table__cell-icon'}
				} or nil,
				Html.Span{
					classes = {props.mobileValue and 'd-none d-md-block' or nil},
					children = props.value
				},
				props.mobileValue and Html.Span{
					classes = {'d-block d-md-none'},
					children = props.mobileValue
				} or nil,
				isSortable and Html.Div{
					classes = {'panel-table__sort'},
					children = IconWidget{
						iconName = 'sort',
						attributes = {
							['data-js-battle-royale'] = 'sort-icon'
						}
					},
				} or nil
			)
		}
	}
end

return Component.component(MatchSummaryFfaTableHeaderCell)

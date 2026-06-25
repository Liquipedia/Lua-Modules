---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/Ffa/TableRowCell
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')

---@class MatchSummaryFfaTableRowCellProps
---@field class? string
---@field sortable? boolean
---@field sortType? string
---@field sortValue? string|number
---@field value? Renderable|Renderable[]

---@param props MatchSummaryFfaTableRowCellProps
---@return VNode
local function MatchSummaryFfaTableRowCell(props)
	local isSortable = props.sortable

	return Html.Div{
		classes = {'panel-table__cell', props.class},
		attributes = {
			['data-sort-type'] = isSortable and props.sortType or nil,
			['data-sort-val'] = isSortable and props.sortValue or nil,
		},
		children = Html.Div{
			classes = {'panel-table__cell-grouped'},
			children = props.value
		}
	}
end

return Component.component(MatchSummaryFfaTableRowCell)

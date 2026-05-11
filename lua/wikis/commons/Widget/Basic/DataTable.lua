---
-- @Liquipedia
-- page=Module:Widget/Basic/DataTable
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local WidgetUtil = Lua.import('Module:Widget/Util')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local Table = Html.Table

---@class DataTableProps: HtmlNodeProps
---@field sortable boolean?
---@field tableCss? table<string, string|number?>
---@field tableAttributes? table<string, string|number?>
---@field wrapperClasses? string[]

---@param props DataTableProps
---@return HtmlNode
local function DataTable(props)
	local isSortable = Logic.readBool(props.sortable)
	return Div{
		children = {
			Table{
				children = props.children,
				classes = WidgetUtil.collect('wikitable', isSortable and 'sortable' or nil, props.classes),
				css = props.tableCss,
				attributes = props.tableAttributes,
			},
		},
		classes = WidgetUtil.collect('table-responsive', props.wrapperClasses),
		attributes = props.attributes,
		css = props.css,
	}
end

return Component.component(DataTable)

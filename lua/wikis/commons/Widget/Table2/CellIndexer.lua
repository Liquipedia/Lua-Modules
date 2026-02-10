---
-- @Liquipedia
-- page=Module:Widget/Table2/CellIndexer
--
-- Internal component to automatically assign column indices to cells
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')

---@class Table2CellIndexer: Widget
---@operator call(Table2CellIndexerProps): Table2CellIndexer
local Table2CellIndexer = Class.new(Widget)

---@class Table2CellIndexerProps
---@field children (Widget|Html|string|number|nil)[]?

Table2CellIndexer.defaultProps = {
	children = {},
}

---@return Widget
function Table2CellIndexer:render()
	local props = self.props
	local children = props.children or {}

	local columnIndex = 1
	local indexedChildren = Array.map(children, function(child)
		if child and type(child) == 'table' and child.props then
			if not child.props.columnIndex then
				child.props.columnIndex = columnIndex
			end
			columnIndex = columnIndex + 1
		end
		return child
	end)

	return HtmlWidgets.Fragment{
		children = indexedChildren,
	}
end

return Table2CellIndexer

---
-- @Liquipedia
-- page=Module:Widget/Table2/CellIndexer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Table2Cell = Lua.import('Module:Widget/Table2/Cell')
local Table2CellHeader = Lua.import('Module:Widget/Table2/CellHeader')
local Table2ColumnIndexContext = Lua.import('Module:Widget/Table2/ColumnIndexContext')

---@class Table2CellIndexer: Widget
---@operator call(Table2CellIndexerProps): Table2CellIndexer
local Table2CellIndexer = Class.new(Widget)

---@class Table2CellIndexerProps
---@field children (Widget|Html|string|number|nil)[]?

---@return Widget
function Table2CellIndexer:render()
	local props = self.props
	local children = props.children or {}

	local columnIndex = 1
	local indexedChildren = Array.map(children, function(child)
		if Class.instanceOf(child, Table2Cell) or Class.instanceOf(child, Table2CellHeader) then
			local explicitIndex = tonumber(child.props.columnIndex)
			if explicitIndex then
				columnIndex = math.max(columnIndex, explicitIndex)
			end

			local wrappedChild = child
			if not child.props.columnIndex then
				wrappedChild = Table2ColumnIndexContext{
					value = columnIndex,
					children = {child},
				}
			end

			local span = tonumber(child.props.colspan) or 1
			if span < 1 then
				span = 1
			end
			columnIndex = columnIndex + span
			return wrappedChild
		end
		return child
	end)

	return HtmlWidgets.Fragment{
		children = indexedChildren,
	}
end

return Table2CellIndexer

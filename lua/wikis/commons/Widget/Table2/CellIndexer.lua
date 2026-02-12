---
-- @Liquipedia
-- page=Module:Widget/Table2/CellIndexer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local Widget = Lua.import('Module:Widget')
local Table2Cell = Lua.import('Module:Widget/Table2/Cell')
local Table2CellHeader = Lua.import('Module:Widget/Table2/CellHeader')
local Table2ColumnIndexContext = Lua.import('Module:Widget/Table2/ColumnIndexContext')

---@class Table2CellIndexerProps
---@field children (Widget|Html|string|number|nil)[]?

---@class Table2CellIndexer: Widget
---@operator call(Table2CellIndexerProps): Table2CellIndexer
---@field props Table2CellIndexerProps
local Table2CellIndexer = Class.new(Widget)

---@return (Widget|Html|string|number|nil)[]
function Table2CellIndexer:render()
	local props = self.props
	local children = props.children or {}

	local columnIndex = 1
	local indexedChildren = Array.map(children, function(child)
		if Class.instanceOf(child, Table2Cell) or Class.instanceOf(child, Table2CellHeader) then
			local cellChild = child --[[@as Table2Cell|Table2CellHeader]]
			local explicitIndex = MathUtil.toInteger(cellChild.props.columnIndex)
			if explicitIndex and explicitIndex >= 1 then
				columnIndex = math.max(columnIndex, explicitIndex)
			end

			local wrappedChild = cellChild --[[@as Table2Cell|Table2CellHeader|Table2ColumnIndexContext]]
			if not cellChild.props.columnIndex then
				wrappedChild = Table2ColumnIndexContext{
					value = columnIndex,
					children = {cellChild},
				}
			end

			local span = MathUtil.toInteger(cellChild.props.colspan) or 1
			if span < 1 then
				span = 1
			end
			columnIndex = columnIndex + span
			return wrappedChild
		end
		return child
	end)

	return indexedChildren
end

return Table2CellIndexer

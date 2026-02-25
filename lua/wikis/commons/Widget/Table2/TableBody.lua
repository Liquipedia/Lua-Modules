---
-- @Liquipedia
-- page=Module:Widget/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local MathUtil = Lua.import('Module:MathUtil')

local Widget = Lua.import('Module:Widget')
local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')
local Table2Cell = Lua.import('Module:Widget/Table2/Cell')
local Table2CellHeader = Lua.import('Module:Widget/Table2/CellHeader')
local Table2Row = Lua.import('Module:Widget/Table2/Row')

---@class Table2BodyProps
---@field children Renderable[]?

---@class Table2Body: Widget
---@operator call(Table2BodyProps): Table2Body
---@field props Table2BodyProps
local Table2Body = Class.new(Widget)

---@return Widget
function Table2Body:render()
	local props = self.props
	local children = props.children or {}

	local stripedChildren = {}
	local stripe = 'even'
	local groupRemaining = 0

	local function toggleStripe()
		stripe = stripe == 'even' and 'odd' or 'even'
	end

	local function getRowMaxRowspan(row)
		if row and row._cachedMaxRowspan then
			return row._cachedMaxRowspan
		end

		local rowChildren = (row and row.props and row.props.children) or {}
		local maxRowspan = 1
		Array.forEach(rowChildren, function(child)
			if Class.instanceOf(child, Table2Cell) or Class.instanceOf(child, Table2CellHeader) then
				local rowspan = MathUtil.toInteger(child.props.rowspan) or 1
				rowspan = math.max(rowspan, 1)
				maxRowspan = math.max(maxRowspan, rowspan)
			end
		end)

		if row then
			row._cachedMaxRowspan = maxRowspan
		end

		return maxRowspan
	end

	Array.forEach(children, function(child)
		if Class.instanceOf(child, Table2Row) then
			if groupRemaining == 0 then
				toggleStripe()
			end

			local maxRowspan = getRowMaxRowspan(child)
			groupRemaining = math.max(groupRemaining, maxRowspan)

			table.insert(stripedChildren, Table2Contexts.BodyStripe{
				value = stripe,
				children = {child},
			})

			groupRemaining = groupRemaining - 1
		else
			table.insert(stripedChildren, child)
		end
	end)

	return Table2Contexts.Section{
		value = 'body',
		children = stripedChildren,
	}
end

return Table2Body

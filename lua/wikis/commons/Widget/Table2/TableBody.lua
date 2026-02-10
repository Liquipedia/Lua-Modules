---
-- @Liquipedia
-- page=Module:Widget/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local Widget = Lua.import('Module:Widget')
local Table2BodyStripe = Lua.import('Module:Widget/Table2/BodyStripe')
local Table2Cell = Lua.import('Module:Widget/Table2/Cell')
local Table2CellHeader = Lua.import('Module:Widget/Table2/CellHeader')
local Table2Row = Lua.import('Module:Widget/Table2/Row')
local Table2Section = Lua.import('Module:Widget/Table2/Section')

---@class Table2BodyProps
---@field children (Widget|Html|string|number|nil)[]?

---@class Table2Body: Widget
---@operator call(Table2BodyProps): Table2Body
local Table2Body = Class.new(Widget)
Table2Body.defaultProps = {}

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
		local rowChildren = (row and row.props and row.props.children) or {}
		local maxRowspan = 1
		Array.forEach(rowChildren, function(child)
			if Class.instanceOf(child, Table2Cell) or Class.instanceOf(child, Table2CellHeader) then
				local rowspan = tonumber(child.props.rowspan) or 1
				rowspan = math.max(rowspan, 1)
				maxRowspan = math.max(maxRowspan, rowspan)
			end
		end)
		return maxRowspan
	end

	Array.forEach(children, function(child)
		if Class.instanceOf(child, Table2Row) then
			if groupRemaining == 0 then
				toggleStripe()
			end

			local maxRowspan = getRowMaxRowspan(child)
			groupRemaining = math.max(groupRemaining, maxRowspan)

			table.insert(stripedChildren, Table2BodyStripe{
				value = stripe,
				children = {child},
			})

			groupRemaining = groupRemaining - 1
		else
			table.insert(stripedChildren, child)
		end
	end)

	return Table2Section{
		value = 'body',
		children = stripedChildren,
	}
end

return Table2Body

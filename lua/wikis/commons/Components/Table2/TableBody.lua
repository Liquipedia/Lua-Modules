---
-- @Liquipedia
-- page=Module:Components/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Component = Lua.import('Module:Components/Component')
local Context = Lua.import('Module:Components/Context')
local FnUtil = Lua.import('Module:FnUtil')
local MathUtil = Lua.import('Module:MathUtil')

local Table2Contexts = Lua.import('Module:Components/Contexts/Table2')
local Table2Cell = Lua.import('Module:Components/Table2/Cell')
local Table2CellHeader = Lua.import('Module:Components/Table2/CellHeader')
local Table2Row = Lua.import('Module:Components/Table2/Row')

---@class Table2BodyProps
---@field children Renderable[]?

---@param props Table2BodyProps
---@param context Context
---@return Renderable
local function Table2Body(props, context)
	local children = props.children or {}

	local stripeEnabled = Context.read(context, Table2Contexts.BodyStripe)
	if stripeEnabled == nil then
		return Context.Provider{
			def = Table2Contexts.Section,
			value = 'body',
			children = children,
		}
	end

	local stripedChildren = {}
	local stripe = 'even'
	local groupRemaining = 0

	local function toggleStripe()
		stripe = stripe == 'even' and 'odd' or 'even'
	end

	---@param row VNode
	local getRowMaxRowspan = FnUtil.memoize(function(row)
		local rowChildren = (row and row.props and row.props.children) or {}
		local maxRowspan = 1

		Array.forEach(rowChildren, function(child)
			local childMt = getmetatable(child)
			if childMt == getmetatable(Table2Cell) or childMt == getmetatable(Table2CellHeader) then
				local rowspan = MathUtil.toInteger(child.props.rowspan) or 1
				rowspan = math.max(rowspan, 1)
				maxRowspan = math.max(maxRowspan, rowspan)
			end
		end)

		return maxRowspan
	end)

	Array.forEach(children, function(child)
		if getmetatable(child) == getmetatable(Table2Row) then
			---@cast child VNode
			if groupRemaining == 0 then
				toggleStripe()
			end

			local maxRowspan = getRowMaxRowspan(child)
			groupRemaining = math.max(groupRemaining, maxRowspan)

			table.insert(stripedChildren, Context.Provider{
				def = Table2Contexts.BodyStripe,
				value = stripe,
				children = {child},
			})

			groupRemaining = groupRemaining - 1
		else
			table.insert(stripedChildren, child)
		end
	end)

	return Context.Provider{
		def = Table2Contexts.Section,
		value = 'body',
		children = stripedChildren,
	}
end

return Component.component(
	Table2Body
)

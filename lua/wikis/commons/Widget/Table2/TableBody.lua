---
-- @Liquipedia
-- page=Module:Widget/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Component = Lua.import('Module:Widget/Component')
local Context = Lua.import('Module:Widget/ComponentContext')
local FnUtil = Lua.import('Module:FnUtil')
local MathUtil = Lua.import('Module:MathUtil')

local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')
local Table2Cell = Lua.import('Module:Widget/Table2/Cell')
local Table2CellHeader = Lua.import('Module:Widget/Table2/CellHeader')
local Table2Row = Lua.import('Module:Widget/Table2/Row')

---@class Table2BodyProps
---@field children? Renderable|Renderable[]

---@param props Table2BodyProps
---@param context Context
---@return Renderable
local function Table2Body(props, context)
	local children = props.children
	---@cast children Renderable[]

	local stripeEnabled = Context.read(context, Table2Contexts.BodyStripe)
	if stripeEnabled == 'disabled' then
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

	---@param row VNode<{children: Renderable|Renderable[]}>
	---@return integer
	local getRowMaxRowspan = FnUtil.memoize(function(row)
		local rowChildren = (row and row.props and row.props.children) or {}
		if type(rowChildren) ~= 'table' then
			rowChildren = {rowChildren}
		end
		local maxRowspan = 1

		Array.forEach(rowChildren, function(child)
			if type(child) == 'table'
					---@diagnostic disable-next-line: undefined-field
					and (child.renderFn == Table2Cell.renderFn or child.renderFn == Table2CellHeader.renderFn) then

				local rowspan = MathUtil.toInteger(child.props.rowspan) or 1
				rowspan = math.max(rowspan, 1)
				maxRowspan = math.max(maxRowspan, rowspan)
			end
		end)

		return maxRowspan
	end)

	Array.forEach(children, function(child)
		---@diagnostic disable-next-line: undefined-field
		if type(child) == 'table' and child.renderFn == Table2Row.renderFn then
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

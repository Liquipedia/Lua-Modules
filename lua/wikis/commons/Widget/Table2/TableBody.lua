---
-- @Liquipedia
-- page=Module:Widget/Table2/TableBody
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Context = Lua.import('Module:Widget/ComponentContext')

local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')

---@class Table2BodyProps
---@field children? Renderable|Renderable[]

---@param props Table2BodyProps
---@param context Context
---@return Renderable
local function Table2Body(props, context)
	local collapseAfter = Context.read(context, Table2Contexts.CollapseAfter)
	return Context.Provider{
		def = Table2Contexts.Section,
		value = 'body',
		children = {Context.Provider{
			def = Table2Contexts.CollapseCounter,
			-- Fresh per body and render, the rows count themselves as they render
			value = collapseAfter and {collapseAfter = collapseAfter, rows = 0} or nil,
			children = props.children or {},
		}},
	}
end

return Component.component(
	Table2Body
)

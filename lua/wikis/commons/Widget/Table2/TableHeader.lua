---
-- @Liquipedia
-- page=Module:Widget/Table2/TableHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Context = Lua.import('Module:Widget/ComponentContext')
local Component = Lua.import('Module:Widget/Component')

local Table2Row = Lua.import('Module:Widget/Table2/Row')
local Table2Contexts = Lua.import('Module:Widget/Contexts/Table2')

---@class Table2HeaderProps
---@field children Renderable[]?

---@param props Table2HeaderProps
---@param context Context
---@return Renderable
local function Table2Header(props, context)
	local rowCount = 0
	local children = Array.map(props.children or {}, function(child)
		---@diagnostic disable-next-line: undefined-field
		if type(child) == 'table' and child.renderFn == Table2Row.renderFn then
			rowCount = rowCount + 1
			local kind = rowCount == 1 and 'title' or 'columns'
			child = Context.Provider{def = Table2Contexts.HeaderRowKind, value = kind, children = {child}}
		end
		return child
	end)

	return Context.Provider{
		def = Table2Contexts.Section,
		value = 'head',
		children = children,
	}
end

return Component.component(
	Table2Header
)

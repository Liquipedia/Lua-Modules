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
---@field children? Renderable|Renderable[]

---@param props Table2HeaderProps
---@param context Context
---@return Renderable
local function Table2Header(props, context)
	local children = props.children
	---@cast children Renderable[]

	local firstRow = true

	return Context.Provider{
		def = Table2Contexts.Section,
		value = 'head',
		children = Array.map(children, function(child)
			---@diagnostic disable-next-line: undefined-field
			if type(child) == 'table' and child.renderFn == Table2Row.renderFn then
				local kind = firstRow and 'title' or 'columns'
				firstRow = false
				child = Context.Provider{def = Table2Contexts.HeaderRowKind, value = kind, children = {child}}
			end
			return child
		end),
	}
end

return Component.component(
	Table2Header
)

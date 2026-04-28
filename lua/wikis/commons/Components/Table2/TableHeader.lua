---
-- @Liquipedia
-- page=Module:Components/Table2/TableHeader
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Context = Lua.import('Module:Components/Context')
local Component = Lua.import('Module:Components/Component')

local Table2Row = Lua.import('Module:Components/Table2/Row')
local Table2Contexts = Lua.import('Module:Components/Contexts/Table2')

---@class Table2HeaderProps
---@field children Renderable[]?

---@param props Table2HeaderProps
---@param context Context
---@return Renderable
local function Table2Header(props, context)
	local rowCount = 0
	local children = Array.map(props.children or {}, function(child)
		if getmetatable(child) == getmetatable(Table2Row) then
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

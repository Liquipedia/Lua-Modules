---
-- @Liquipedia
-- page=Module:Components/Context
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ComponentCore = Lua.import('Module:Components/Component')
local Types = Lua.import('Module:Components/Types')

local Context = {}

-- Create a unique Context Definition with a default value
---@generic T
---@param defaultValue T
---@return ContextDef<T>
function Context.create(defaultValue)
	return { defaultValue = defaultValue }
end

-- Read from Context
---@generic T
---@param node Context<any>?
---@param def ContextDef<T>
---@return T
function Context.read(node, def)
	while node do
		local props = node.props
		if props.def == def then
			return props.value
		end
		node = props.parent
	end
	return def.defaultValue
end

-- Set values for contexts
Context.Provider = setmetatable(
	{ renderFn = Types.CONTEXT_PROVIDER},
	ComponentCore.ComponentMT
) --[[@as ContextComponent<any>]]

return Context

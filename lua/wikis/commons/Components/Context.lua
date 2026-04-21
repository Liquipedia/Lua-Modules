---
-- @Liquipedia
-- page=Module:Components/Context
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local ComponentCore = Lua.import('Module:Lib/Component/Core')

local Context = {}

-- Create a unique Context Definition with a default value
---@generic P
---@param defaultValue P
---@return ContextDef<P>
function Context.create(defaultValue)
	return { defaultValue = defaultValue }
end

-- Read from Context
---@generic P
---@param node Context?
---@param contextDef ContextDef<P>
---@return P
function Context.read(node, contextDef)
	while node do
		local props = node.props
		if props.def == contextDef then
			return props.value
		end
		node = props.parent
	end
	return contextDef.defaultValue
end

-- Set values for contexts
Context.Provider = setmetatable(
	{ renderFn = 'CONTEXT_PROVIDER'},
	ComponentCore.ComponentMT
) --[[@as ContextComponent]]

return Context

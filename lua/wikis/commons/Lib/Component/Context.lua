---
local Context = {}
local ComponentCore = require('Module:Lib/Component/Core')

-- Create a unique Context Definition with a default value
---@param defaultValue any
---@return ContextDef
function Context.create(defaultValue)
	return { defaultValue = defaultValue }
end

-- Read from Context
---@param node Context
---@param contextDef ContextDef
---@return any
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

-- The Provider is a standard Callable Component
---@type Context
Context.Provider = setmetatable({ renderFn = 'CONTEXT_PROVIDER' }, ComponentCore.ComponentMT)

return Context
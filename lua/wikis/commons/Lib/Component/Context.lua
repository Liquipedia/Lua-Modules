-- Module:Functional/Context
local Context = {}
local System = require('Module:Functional/System')

-- Create a unique Context Definition / Identity
function Context.create(defaultValue)
	return { defaultValue = defaultValue }
end

-- Read from Context (Traverse the Linked List)
function Context.read(node, contextDef)
	while node do
		if node.def == contextDef then
			return node.value
		end
		node = node.parent
	end
	return contextDef.defaultValue
end

-- The Provider is a standard Callable Component
-- The renderer will natively recognize the "CONTEXT_PROVIDER" string
Context.Provider = setmetatable({
	renderFn = "CONTEXT_PROVIDER"
}, System.ComponentMT)

return Context
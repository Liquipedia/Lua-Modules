-- Module:Functional/System
local System = {}

-- Lazy-load renderer to avoid circular dependency issues during module initialization
local function getRenderer()
	return require('Module:Functional/Renderer')
end

-- METATABLE 1: Virtual Nodes (The table returned after calling a component)
local VNodeMT = {
	-- Automatically trigger rendering when concatenated or used as a string
	__tostring = function(self)
		return getRenderer().render(self, nil)
	end,

	__index = {
		-- Fulfill legacy requirements: legacy code can call node:_build()
		_build = function(self)
			return tostring(self)
		end
	}
}

-- METATABLE 2: Component Definitions (Makes them callable and handles defaults)
local ComponentMT = {
	__call = function(self, props)
		props = props or {}

		-- Apply DefaultProps via lightweight metatable (Zero table copying)
		if self.defaultProps and not getmetatable(props) then
			setmetatable(props, { __index = self.defaultProps })
		end

		-- Return the lightweight Virtual Node description
		local vNode = {
			type = self.renderFn,
			props = props
		}

		return setmetatable(vNode, VNodeMT)
	end
}

-- Factory to create new Functional Components
function System.component(renderFunction, defaultProps)
	return setmetatable({
		renderFn = renderFunction,
		defaultProps = defaultProps
	}, ComponentMT)
end

-- Factory to create pre-wrapped HTML tags
function System.tag(tagName)
	return setmetatable({ renderFn = tagName }, ComponentMT)
end

-- Export pre-defined common HTML elements
System.div = System.tag('div')
System.span = System.tag('span')

System.VNodeMT = VNodeMT
System.ComponentMT = ComponentMT

return System
---
local ComponentCore = {}

-- Lazy-load renderer to avoid circular dependency issues
local function getRenderer()
	return require('Module:Lib/Component/Renderer')
end

-- Virtual Nodes (The table returned after calling a component)
ComponentCore.VNodeMT = {
	-- Automatically trigger rendering
	__tostring = function(self)
		return getRenderer().render(self)
	end,

	__index = {
		-- Allows to be used as a node in the third part html library (mw.html).
		_build = function(self, ret)
			table.insert(ret, tostring(self))
		end
	}
}

-- Component Definitions
ComponentCore.ComponentMT = {
	__call = function(self, props)
		props = props or {}

		-- Apply DefaultProps via lightweight metatable
		-- Only shallow default props allowed
		if self.defaultProps then
			setmetatable(props, { __index = self.defaultProps })
		end

		return setmetatable({
			renderFn = self.renderFn,
			props = props
		}, ComponentCore.VNodeMT)
	end
}

-- Factory to create Functional Components
---@generic P
---@param renderFunction fun(props: P, context?: Context): Renderable
---@param defaultProps P? -- May not contain table values
---@return Component<P>
function ComponentCore.component(renderFunction, defaultProps)
	---@diagnostic disable-next-line: return-type-mismatch
	return setmetatable({
		renderFn = renderFunction,
		defaultProps = defaultProps
	}, ComponentCore.ComponentMT)
end

-- Factory to create HTML tags
---@param tagName string|nil
---@return Component<table>
function ComponentCore.tag(tagName)
	---@diagnostic disable-next-line: return-type-mismatch
	return setmetatable({ renderFn = tagName }, ComponentCore.ComponentMT)
end

return ComponentCore

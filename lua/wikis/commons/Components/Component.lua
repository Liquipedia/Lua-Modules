---
-- @Liquipedia
-- page=Module:Components/Component
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@class VNode<P>
---@field renderFn string|Component<P>
---@field props P

---@alias Context<T> VNode<{parent: Context?, def: ContextDef<T>, value: T, children: Renderable}>
---@alias HtmlNode VNode<{classes?: string[], css?: table, attr?: table, children: Renderable}>

---@alias Renderable string|Html|Widget|number|VNode

---@alias ContextDef<T> {defaultValue: T}

---@alias Component<P> fun(props: P, context: Context?): VNode<P>
---@alias ContextComponent<T> Component<{parent: Context?, def: ContextDef<T>, value: T, children: Renderable}>
---@alias HtmlComponent Component<{classes?: string[], css?: table, attr?: table, children: Renderable}>

local Lua = require('Module:Lua')
local Renderer = Lua.import('Module:Components/Renderer')

local ComponentCore = {}

-- Virtual Nodes (The table returned after calling a component)
ComponentCore.VNodeMT = {
	-- Automatically trigger rendering
	__tostring = function(self)
		return Renderer.render(self)
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
---@param tagName string
---@return HtmlComponent
function ComponentCore.tag(tagName)
	return setmetatable({ renderFn = tagName }, ComponentCore.ComponentMT) --[[@as HtmlComponent]]
end

return ComponentCore

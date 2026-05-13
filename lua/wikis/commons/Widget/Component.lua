---
-- @Liquipedia
-- page=Module:Widget/Component
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---@alias Renderable string|Html|Widget|number|VNode

---@alias ContextDef<T> {defaultValue: T}
---@alias ContextParam<T> {def: ContextDef<T>, value: T, children?: Renderable|Renderable[]}
---@alias HtmlParam {classes?: string[], css?: table, attributes?: table, children?: Renderable|Renderable[]}

---@class VNode<P>
---@field renderFn string|fun(props: P, context?: Context?): Renderable
---@field props P

---@alias Context<T> {props:{parent: Context?, def: ContextDef<T>, value: T}}

---@alias ContextNode<T> VNode<ContextParam<T>>
---@alias HtmlNode VNode<HtmlParam>

---@alias Component<P> fun(props?: P, context: Context?): VNode<P>
---@alias ContextComponent<T> Component<ContextParam<T>>
---@alias HtmlComponent Component<HtmlParam>

local Lua = require('Module:Lua')
local Renderer = Lua.import('Module:Widget/Renderer')

local ComponentCore = {}

-- Virtual Nodes (The table returned after calling a component)
ComponentCore.VNodeMT = {
	-- Automatically trigger rendering
	__tostring = Renderer.render,

	__index = {
		-- Allows to be used as a node in the third party html library (mw.html).
		_build = function(self, ret)
			table.insert(ret, tostring(self))
		end
	}
}

--- Highly efficient check for if a node is actually an array of nodes, or just a single node
---@param node Renderable|Renderable[]|nil
---@return boolean
local function isSingleNode(node)
	if type(node) ~= 'table' then
		return true
	end

	-- VNodes always have this key
	if node.renderFn ~= nil then
		return true
	end

	---@cast node -VNode

	-- Widget (render) and mw.html (_build)
	if node.render ~= nil or node._build ~= nil then
		return true
	end

	---@cast node -Html
	---@cast node -Widget

	-- Array is the only allowed type of Renderable left
	return false
end

-- Component Definitions
ComponentCore.ComponentMT = {
	__call = function(self, props)
		props = props or {}

		-- Apply DefaultProps via lightweight metatable
		-- Only shallow default props allowed, or empty tables
		if self.defaultProps then
			setmetatable(props, { __index = self.defaultProps })
		end

		if isSingleNode(props.children) then
			props.children = { props.children }
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

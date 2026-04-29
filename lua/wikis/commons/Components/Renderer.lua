---
-- @Liquipedia
-- page=Module:Components/Renderer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Types = require('Module:Components/Types')

local Renderer = {}

--- Renders a Virtual Node (VNode) into a string
---@param vNode Renderable|Renderable[]|nil
---@param context Context?
---@return string
function Renderer.render(vNode, context)
	if not vNode then
		return ''
	end

	local vNodeType = type(vNode)

	-- Handle Arrays
	-- For performance reasons we do a heuristic check for array-like tables
	if vNodeType == 'table' and vNode[1] then
		local output = {}
		for _, child in ipairs(vNode) do
			table.insert(output, Renderer.render(child, context))
		end
		return table.concat(output)
	end

	---@cast vNode Renderable

	-- Handle Primitives (Strings/Numbers)
	if vNodeType == 'string' or vNodeType == 'number' then
		return tostring(vNode)
	end

	if vNodeType ~= 'table' then
		mw.logObject(vNode, 'Invalid VNode')
		error('Invalid VNode: ' .. tostring(vNode))
	end

	-- Empty Table
	if next(vNode) == nil then
		return ''
	end

	local renderFn = vNode.renderFn

	-- Backward Compatibility (with Widgets and mw.html)
	if not renderFn then
		if vNode.__tostring or vNode._build then
			return tostring(vNode)
		end
		mw.log('ERROR! Bad renderable:' .. mw.dumpObject(vNode))
		error('Invalid Table passed as Renderable')
	end

	---@cast vNode -Widget
	---@cast vNode -Html

	-- Handle Context Providers
	if renderFn == Types.CONTEXT_PROVIDER then
		---@cast vNode ContextNode<any>
		-- Push a new link onto the Context chain
		local newContext = {
			props = {
				parent = context,
				def = vNode.props.def,
				value = vNode.props.value
			}
		}
		return Renderer.render(vNode.props.children, newContext)
	end

	-- Handle HTML Tags
	if type(renderFn) == 'string' then
		---@cast vNode HtmlNode
		local props = vNode.props
		local tagName = renderFn
		local tag
		if tagName == 'fragment' then
			tag = mw.html.create()
		else
			tag = mw.html.create(tagName)
		end

		if props.classes then
			tag:addClass(table.concat(props.classes, ' '))
		end
		if props.css then tag:css(props.css) end
		if props.attributes then tag:attr(props.attributes) end

		if props.children then
			tag:node(Renderer.render(props.children, context))
		end

		return tostring(tag)
	end

	-- Handle Functional Components
	if type(renderFn) == 'function' then
		-- Execute the function with props and the current context pointer
		local result = renderFn(vNode.props, context)
		return Renderer.render(result, context)
	end

	return ''
end

return Renderer

---
-- @Liquipedia
-- page=Module:Components/Renderer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Renderer = {}

--- Renders a Virtual Node (VNode) into a string
---@param vNode Renderable|Renderable[]
---@param context Context?
---@return string|Html
function Renderer.render(vNode, context)
	if not vNode then return "" end

	local vNodeType = type(vNode)

	-- Handle Arrays
	if vNodeType == "table" and vNode[1] then
		local output = {}
		for _, child in ipairs(vNode) do
			table.insert(output, Renderer.render(child, context))
		end
		return table.concat(output)
	end

	---@cast vNode Renderable

	-- Handle Primitives (Strings/Numbers)
	if vNodeType == "string" or vNodeType == "number" then
		return tostring(vNode)
	end

	if vNodeType ~= "table" then
		mw.logObject(vNode, 'Invalid VNode')
		error("Invalid VNode: " .. tostring(vNode))
	end

	local renderFn = vNode.renderFn

	-- Backward Compatibility with Widgets and mw.html
	if not renderFn then
		return tostring(vNode)
	end

	---@cast vNode -Widget
	---@cast vNode -Html

	-- Handle Context Providers
	if renderFn == "CONTEXT_PROVIDER" then
		---@cast vNode Context
		-- Push a new link onto the Context chain
		local newContext = {
			parent = context,
			def = vNode.props.def,
			value = vNode.props.value
		}
		return Renderer.render(vNode.props.children, newContext)
	end

	-- Handle HTML Tags
	if type(renderFn) == "string" then
		---@cast vNode HtmlNode
		local props = vNode.props
		local tagName = renderFn
		local tag = mw.html.create(tagName)

		if props.classes then
			tag:addClass(table.concat(props.classes, " "))
		end
		if props.css then tag:css(props.css) end
		if props.attr then tag:attr(props.attr) end

		if props.children then
			tag:node(Renderer.render(props.children, context))
		end

		return tostring(tag)
	end

	-- Handle Functional Components
	if type(renderFn) == "function" then
		-- Execute the function with props and the current context pointer
		local result = renderFn(vNode.props, context)
		return Renderer.render(result, context)
	end

	return ""
end

return Renderer

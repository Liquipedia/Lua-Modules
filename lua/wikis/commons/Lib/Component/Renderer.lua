-- Module:Functional/Renderer
local Renderer = {}
local Context = require('Module:Functional/Context')
local System = require('Module:Functional/System')

function Renderer.render(vNode, contextHead)
	if not vNode then return "" end

	-- 1. Handle Primitives (Strings/Numbers)
	local vNodeType = type(vNode)
	if vNodeType == "string" or vNodeType == "number" then
		return tostring(vNode)
	end

	-- 2. Handle Arrays (Fragments / Lists of children)
	if vNodeType == "table" and vNode[1] then
		local output = {}
		for _, child in ipairs(vNode) do
			table.insert(output, Renderer.render(child, contextHead))
		end
		return table.concat(output)
	end

	-- 3. Backward Compatibility: Legacy Class Widgets
	if vNodeType == "table" and not vNode.type then
		if type(vNode.render) == "function" then
			return tostring(vNode:render())
		elseif type(vNode._build) == "function" and getmetatable(vNode) ~= System.VNodeMT then
			return tostring(vNode:_build())
		end
	end

	local nodeType = vNode.type
	local props = vNode.props or {}

	-- 4. Handle Context Providers
	if nodeType == "CONTEXT_PROVIDER" then
		-- Push a new link onto the Context chain
		local newHead = {
			parent = contextHead,
			def = props.contextDef,
			value = props.value
		}
		return Renderer.render(props.children, newHead)
	end

	-- 5. Handle Functional Components
	if type(nodeType) == "function" then
		-- Execute the function with props and the current context pointer
		local result = nodeType(props, contextHead)
		return Renderer.render(result, contextHead)
	end

	-- 6. Handle HTML Tags (Leaf Nodes)
	if type(nodeType) == "string" then
		local tag = mw.html.create(nodeType)

		if props.classes then
			tag:addClass(table.concat(props.classes, " "))
		end
		if props.css then tag:css(props.css) end
		if props.attr then tag:attr(props.attr) end

		if props.children then
			tag:node(Renderer.render(props.children, contextHead))
		end

		return tag
	end

	return ""
end

return Renderer
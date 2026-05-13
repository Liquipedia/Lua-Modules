---
-- @Liquipedia
-- page=Module:Widget/Renderer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Types = Lua.import('Module:Widget/Types')

local Renderer = {}

-- List of HTML tags that cannot have children and do not need closing tags
local selfClosingTags = {
	area = true,
	base = true,
	br = true,
	col = true,
	command = true,
	embed = true,
	hr = true,
	img = true,
	input = true,
	keygen = true,
	link = true,
	meta = true,
	param = true,
	source = true,
	track = true,
	wbr = true,
}

-- Basic attribute escaper (prevents quotes from breaking HTML)
local htmlencodeMap = {
	['>'] = '&gt;',
	['<'] = '&lt;',
	['&'] = '&amp;',
	['"'] = '&quot;',
}

---@param str any
---@return string
local function escapeAttr(str)
	if type(str) ~= 'string' then
		str = tostring(str)
	end
	return (str:gsub('[><&"]', htmlencodeMap))
end

--- Builds an HTML string from the given tag, props, and children
---@param tag string
---@param props {classes?: string[], css?: table<string, string>, attributes?: table<string, string|boolean>}
---@param renderedChildren string?
---@return string
local function buildHtmlString(tag, props, renderedChildren)
	local buffer = { '<', tag }

	if props.classes and #props.classes > 0 then
		table.insert(buffer, ' class="')
		table.insert(buffer, escapeAttr(table.concat(props.classes, ' ')))
		table.insert(buffer, '"')
	end

	if props.css then
		table.insert(buffer, ' style="')
		for key, value in pairs(props.css) do
			table.insert(buffer, key)
			table.insert(buffer, ':')
			table.insert(buffer, escapeAttr(value))
			table.insert(buffer, ';')
		end
		table.insert(buffer, '"')
	end

	if props.attributes then
		for key, value in pairs(props.attributes) do
			if type(value) == 'boolean' then
				-- Boolean attributes like `disabled` or `checked`
				if value == true then
					table.insert(buffer, ' ')
					table.insert(buffer, key)
				end
			else
				table.insert(buffer, ' ')
				table.insert(buffer, key)
				table.insert(buffer, '="')
				table.insert(buffer, escapeAttr(value))
				table.insert(buffer, '"')
			end
		end
	end

	if selfClosingTags[tag] then
		table.insert(buffer, ' />')
	else
		table.insert(buffer, '>')
		if renderedChildren and renderedChildren ~= '' then
			table.insert(buffer, renderedChildren)
		end
		table.insert(buffer, '</')
		table.insert(buffer, tag)
		table.insert(buffer, '>')
	end

	return table.concat(buffer)
end

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
		local output = Array.map(vNode, function(child)
			return Renderer.render(child, context)
		end)
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
		local renderedChildren = ''
		if vNode.props.children then
			renderedChildren = Renderer.render(vNode.props.children, context)
		end

		if renderFn == 'fragment' then
			return renderedChildren
		end

		return buildHtmlString(renderFn, vNode.props, renderedChildren)
	end

	-- Handle Functional Components
	if type(renderFn) == 'function' then
		-- Execute the function with props and the current context pointer
		local result = renderFn(vNode.props, context)
		return Renderer.render(result, context)
	end

	mw.logObject(renderFn, 'Invalid renderFn')
	mw.logObject(vNode, 'VNode with invalid renderFn')
	error('Unsupported renderFn type: ' .. type(renderFn))
end

return Renderer

---
-- @Liquipedia
-- page=Module:Widget/Renderer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ErrorDisplay = Lua.import('Module:Error/Display')
local Logic = Lua.import('Module:Logic')
local Types = Lua.import('Module:Widget/Types')

local Renderer = {}

-- Tags that can not have children
local SELF_CLOSING_TAGS = {
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

local HTML_ENCODE_MAP = {
	['>'] = '&gt;',
	['<'] = '&lt;',
	['&'] = '&amp;',
	['"'] = '&quot;',
}

local CLOSING_TAGS = setmetatable({}, {__index = function(closingTags, tagName)
	closingTags[tagName] = '</' .. tagName .. '>'
	return closingTags[tagName]
end})

-- Strip markers contain quotes, which have to stay unescaped for the markers to be expanded
local STRIP_MARKER_CHARACTER = '\127'
local ESCAPED_STRIP_MARKER_PREFIX = '\127\'&quot;`UNIQ%-'
local STRIP_MARKER_PREFIX = '\127\'"`UNIQ-'
local ESCAPED_STRIP_MARKER_SUFFIX = '%-QINU`&quot;\'\127'
local STRIP_MARKER_SUFFIX = '-QINU`"\'\127'

---Escapes a value for use in an attribute, keeping strip markers intact
---@param value string|number
---@return string
local function escapeAttributeValue(value)
	local escaped = string.gsub(value, '[<>&"]', HTML_ENCODE_MAP)
	if not escaped:find(STRIP_MARKER_CHARACTER, 1, true) then
		return escaped
	end
	return (escaped
		:gsub(ESCAPED_STRIP_MARKER_PREFIX, STRIP_MARKER_PREFIX)
		:gsub(ESCAPED_STRIP_MARKER_SUFFIX, STRIP_MARKER_SUFFIX))
end

---@param value any
---@return boolean
local function isStringOrNumber(value)
	local valueType = type(value)
	return valueType == 'string' or valueType == 'number'
end

---@param name any
---@return boolean
local function isValidAttributeName(name)
	return type(name) == 'string' and name:match('^[a-zA-Z_:][a-zA-Z0-9_.:-]*$') ~= nil
end

---@param css table?
---@param styleAttribute any
---@return string?
local function buildStyle(css, styleAttribute)
	local styles
	if css then
		for name, value in pairs(css) do
			if isStringOrNumber(name) and isStringOrNumber(value) then
				styles = styles or {}
				table.insert(styles, name .. ':' .. value)
			end
		end
	end
	if isStringOrNumber(styleAttribute) then
		styles = styles or {}
		table.insert(styles, styleAttribute)
	end
	return styles and table.concat(styles, ';') or nil
end

---Builds the opening tag. A class or style attribute is merged into the classes or css,
---attributes with an invalid name or value are left out.
---@param tagName string
---@param props {classes?: string[], css?: table, attributes?: table}
---@return string
local function buildOpeningTag(tagName, props)
	local attributes = props.attributes
	local parts = {'<', tagName}

	local classes = props.classes and table.concat(props.classes, ' ') or nil
	local classAttribute = attributes and attributes.class
	if isStringOrNumber(classAttribute) then
		classes = classes and (classes .. ' ' .. classAttribute) or classAttribute
	end
	if classes then
		table.insert(parts, ' class="' .. escapeAttributeValue(classes) .. '"')
	end

	if attributes then
		for name, value in pairs(attributes) do
			if name ~= 'class' and name ~= 'style' and isValidAttributeName(name) and isStringOrNumber(value) then
				table.insert(parts, ' ' .. name .. '="' .. escapeAttributeValue(value) .. '"')
			end
		end
	end

	local style = buildStyle(props.css, attributes and attributes.style)
	if style then
		table.insert(parts, ' style="' .. escapeAttributeValue(style) .. '"')
	end

	table.insert(parts, SELF_CLOSING_TAGS[tagName] and ' />' or '>')
	return table.concat(parts)
end

--- Renders a Virtual Node (VNode) into a string
---@param vNode Renderable|Renderable[]|nil
---@param context Context?
---@return string
function Renderer.render(vNode, context)
	local buffer = {}
	Renderer._renderInto(vNode, context, buffer)
	return table.concat(buffer)
end

--- Renders a Virtual Node (VNode) into the buffer
---@package
---@param vNode Renderable|Renderable[]|nil
---@param context Context?
---@param buffer string[]
function Renderer._renderInto(vNode, context, buffer)
	if not vNode then
		return
	end

	local vNodeType = type(vNode)

	-- Handle Arrays
	-- For performance reasons we do a heuristic check for array-like tables
	if vNodeType == 'table' and vNode[1] then
		for _, child in ipairs(vNode) do
			Renderer._renderInto(child, context, buffer)
		end
		return
	end

	---@cast vNode Renderable

	-- Handle Primitives (Strings/Numbers)
	if vNodeType == 'string' or vNodeType == 'number' then
		table.insert(buffer, tostring(vNode))
		return
	end

	if vNodeType ~= 'table' then
		mw.logObject(vNode, 'Invalid VNode')
		error('Invalid VNode: ' .. tostring(vNode))
	end

	-- Empty Table
	if next(vNode) == nil then
		return
	end

	local renderFn = vNode.renderFn

	-- Backward Compatibility (with Widgets and mw.html)
	if not renderFn then
		if vNode.__tostring or vNode._build then
			table.insert(buffer, tostring(vNode))
			return
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
				value = vNode.props.value,
			}
		}
		Renderer._renderInto(vNode.props.children, newContext, buffer)
		return
	end

	-- Handle Error Boundaries
	-- Own buffer, so a failing subtree outputs nothing
	if renderFn == Types.ERROR_BOUNDARY then
		---@cast vNode ErrorBoundaryNode
		local props = vNode.props
		table.insert(buffer, Logic.tryOrElseLog(
			function ()
				return Renderer.render(props.children, context)
			end,
			function (error)
				local fallback = props.fallback
				if type(fallback) == 'function' then
					return Renderer.render(fallback(error, context), context)
				end
				return tostring(ErrorDisplay.InlineError(error))
			end,
			function (error)
				error.header = 'Error occurred in building:'
				return error
			end
		))
		return
	end

	-- Handle HTML Tags
	if type(renderFn) == 'string' then
		---@cast vNode HtmlNode
		local props = vNode.props
		table.insert(buffer, buildOpeningTag(renderFn, props))
		if SELF_CLOSING_TAGS[renderFn] then
			return
		end
		Renderer._renderInto(props.children, context, buffer)
		table.insert(buffer, CLOSING_TAGS[renderFn])
		return
	end

	-- Handle Functional Components
	if type(renderFn) == 'function' then
		-- Execute the function with props and the current context pointer
		local result = renderFn(vNode.props, context)
		Renderer._renderInto(result, context, buffer)
		return
	end

	mw.logObject(renderFn, 'Invalid renderFn')
	mw.logObject(vNode, 'VNode with invalid renderFn')
	error('Unsupported renderFn type: ' .. type(renderFn))
end

return Renderer

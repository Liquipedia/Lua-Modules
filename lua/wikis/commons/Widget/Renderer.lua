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

-- Strip markers contain this character
local STRIP_MARKER_CHARACTER = '\127'

---@param value string|number
---@return string
local function htmlEncode(value)
	return (string.gsub(value, '[<>&"]', HTML_ENCODE_MAP))
end

---@param value string|number
---@return boolean
local function hasStripMarker(value)
	return type(value) == 'string' and value:find(STRIP_MARKER_CHARACTER, 1, true) ~= nil
end

---Whether mw.html outputs the css name or value unchanged (strip markers excluded)
---@param value any
---@return boolean
local function isPlainCssValue(value)
	local valueType = type(value)
	return valueType == 'number' or valueType == 'string' and not value:find('[^\32-\57\60-\126]')
end

---Whether mw.html outputs the attribute unchanged
---@param name any
---@param value any
---@return boolean
local function isPlainAttribute(name, value)
	local valueType = type(value)
	return type(name) == 'string'
		and name ~= 'class' and name ~= 'style'
		and (valueType == 'string' or valueType == 'number')
		and not hasStripMarker(value)
		and name:match('^[a-zA-Z_:][a-zA-Z0-9_.:-]*$') ~= nil
end

---Builds the opening tag like mw.html does. Returns nil for input that needs mw.html.
---@param tagName string
---@param props {classes?: string[], css?: table, attributes?: table}
---@return string?
local function buildOpeningTag(tagName, props)
	if not tagName:match('^[a-zA-Z0-9]+$') then
		return
	end
	local parts = {'<', tagName}
	if props.classes then
		local classes = table.concat(props.classes, ' ')
		if hasStripMarker(classes) then
			return
		end
		table.insert(parts, ' class="' .. htmlEncode(classes) .. '"')
	end
	for name, value in pairs(props.attributes or {}) do
		if not isPlainAttribute(name, value) then
			return
		end
		table.insert(parts, ' ' .. name .. '="' .. htmlEncode(value) .. '"')
	end
	if props.css and next(props.css) ~= nil then
		local styles = {}
		for name, value in pairs(props.css) do
			if not isPlainCssValue(name) or not isPlainCssValue(value) then
				return
			end
			table.insert(styles, htmlEncode(name .. ':' .. value))
		end
		table.insert(parts, ' style="' .. table.concat(styles, ';') .. '"')
	end
	table.insert(parts, SELF_CLOSING_TAGS[tagName] and ' />' or '>')
	return table.concat(parts)
end

---Builds the opening tag with mw.html.
---@param tagName string
---@param props {classes?: string[], css?: table, attributes?: table}
---@return string
local function buildOpeningTagWithMwHtml(tagName, props)
	local tag = mw.html.create(tagName)

	if props.classes then
		tag:addClass(table.concat(props.classes, ' '))
	end
	if props.css then tag:css(props.css) end
	if props.attributes then tag:attr(props.attributes) end

	local emptyTag = tostring(tag)
	if SELF_CLOSING_TAGS[tagName] then
		return emptyTag
	end
	return emptyTag:sub(1, -#CLOSING_TAGS[tagName] - 1)
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
		table.insert(buffer, buildOpeningTag(renderFn, props) or buildOpeningTagWithMwHtml(renderFn, props))
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

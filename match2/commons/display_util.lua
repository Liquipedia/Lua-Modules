local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local TypeUtil = require('Module:TypeUtil')

local DisplayUtil = {propTypes = {}, types = {}}

--[[
Checks that the props to be used by a display component satisfy type
constraints. Throws if it does not.

For performance reasons, type checking is disabled unless the forceTypeCheck
developer flag is enabled via {{#vardefine:forceTypeCheck|1}}. Certain other
developer flags like matchGroupDev can also enable type checking.

By default this only checks types of properties, and not their contents. If
forceTypeCheck is enabled, then the contents of table properties are checked up
to 4 deep. Specify options.maxDepth to increase the depth.
]]
DisplayUtil.assertPropTypes = function(props, propTypes, options)
	local DevFlags = require('Module:DevFlags')
	if not (DevFlags.matchGroupDev or DevFlags.forceTypeCheck) then
		return
	end

	options = options or {}

	local errors = TypeUtil.checkValue(
		props,
		TypeUtil.struct(propTypes),
		{
			maxDepth = options.maxDepth or (DevFlags.forceTypeCheck and 5 or 1),
			name = 'props',
		}
	)
	if #errors > 0 then
		error(table.concat(errors, '\n'), 2)
	end
end

DisplayUtil.propTypes.LuaError = {
	message = 'string',
	backtrace = 'string',
}

-- Shows the message and stack trace of a lua error.
function DisplayUtil.LuaError(props)
	DisplayUtil.assertPropTypes(props, DisplayUtil.propTypes.LuaError)
	local messageNode = mw.html.create('div')
		:addClass('error')
		:css('font-weight', 'bold')
		:wikitext('Lua error: ' .. props.message)
	local backtraceNode = mw.html.create('div')
		:wikitext('Backtrace:<br>')
		:wikitext(props.backtrace)
	return mw.html.create('div')
		:node(messageNode)
		:node(backtraceNode)
end

--[[
Attempts to render a component written in the pure function style. If an error
is encountered when rendering the component, show the error and stack trace
instead of the component.
]]
function DisplayUtil.TryPureComponent(Component, props)
	local resultNode, errorNode = DisplayUtil.try(function() return Component(props) end)
	return errorNode or resultNode
end

--[[
Attempts to invoke a function. If successful, returns the result. If an error
is encountered, render the error and stack trace, and return it in the 2nd return
value.
]]
function DisplayUtil.try(f)
	local result, errorNode
	xpcall(function()
		result = f()
	end, function(message)
		local backtrace = debug.traceback()
		mw.log('Error occured when invoking a function: (caught by DisplayUtil.try)')
		mw.log(message)
		mw.log(backtrace)
		errorNode = DisplayUtil.LuaError({
			message = message,
			backtrace = backtrace,
		})
	end)
	return result, errorNode
end

DisplayUtil.types.OverflowModes = TypeUtil.literalUnion('ellipsis', 'wrap', 'hidden')

--[[
Specifies overflow behavior on a block element. mode can be 'ellipsis', 'wrap',
or 'hidden'.
]]
function DisplayUtil.applyOverflowStyles(node, mode)
	return node
		:css('overflow', (mode == 'ellipsis' or mode == 'hidden') and 'hidden' or nil)
		:css('overflow-wrap', mode == 'wrap' and 'break-word' or nil)
		:css('text-overflow', mode == 'ellipsis' and 'ellipsis' or nil)
		:css('white-space', (mode == 'ellipsis' or mode == 'hidden') and 'pre' or 'normal')
end

-- Whether a value is a mediawiki html node.
local mwHtmlMetatable = FnUtil.memoize(function()
	return getmetatable(mw.html.create('div'))
end)
function DisplayUtil.isMwHtmlNode(x)
	return type(x) == 'table'
		and getmetatable(x) == mwHtmlMetatable()
end

--[[
Like Array.flatten, except that mediawiki html nodes are not considered arrays.
]]
function DisplayUtil.flattenArray(elems)
	local flattened = {}
	for _, elem in ipairs(elems) do
		if type(elem) == 'table'
			and not DisplayUtil.isMwHtmlNode(elem) then
			Array.extendWith(flattened, elem)
		elseif elem then
			table.insert(flattened, elem)
		end
	end
	return flattened
end

--[===[
Clears the link param in a wikicode link.

Example:
DisplayUtil.removeLinkFromWikiLink('[[File:ZergIcon.png|14px|link=Zerg]]')
-- returns '[[File:ZergIcon.png|14px|link=]]''
]===]
function DisplayUtil.removeLinkFromWikiLink(text)
	local textNoLink = text:gsub('link=[^|%]]*', 'link=')
	return textNoLink
end

return DisplayUtil

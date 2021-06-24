local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local TypeUtil = require('Module:TypeUtil')

local DisplayUtil = {propTypes = {}, types = {}}

--[[
Checks that the props to be used by a display component satisfy type
constraints. Throws if it does not.

For performance reasons, this only checks types of properties, and does not
check contents inside table properties. Specify options.maxDepth to override
this behavior.
]]
DisplayUtil.assertPropTypes = function(props, propTypes, options)
	options = options or {}

	local errors = TypeUtil.checkValue(
		props,
		TypeUtil.struct(propTypes),
		{maxDepth = options.maxDepth or 1, name = 'props'}
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
DisplayUtil.LuaError = function(props)
	DisplayUtil.assertPropTypes(props, DisplayUtil.propTypes.LuaError)
	return mw.html.create('div')
		:addClass('scribunto-error')
		:node(mw.html.create('div'):wikitext(props.message))
		:node(mw.html.create('div'):wikitext(props.backtrace))
end

--[[
Attempts to render a component written in the pure function style. If an error
is encountered when rendering the component, show the error and stack trace
instead of the component.
]]
DisplayUtil.TryPureComponent = function(Component, props)
	local node
	xpcall(function()
		node = Component(props)
	end, function(message)
		local backtrace = debug.traceback()
		mw.log('Error occured when redering a component: (caught by DisplayUtil.TryPureComponent)')
		mw.log(message)
		mw.log(backtrace)
		node = DisplayUtil.LuaError({
			message = message,
			backtrace = backtrace,
		})
	end)
	return node
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
		:css('white-space', (mode == 'ellipsis' or mode == 'hidden') and 'pre' or 'unset')
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

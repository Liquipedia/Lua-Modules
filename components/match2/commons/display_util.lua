---
-- @Liquipedia
-- wiki=commons
-- page=Module:DisplayUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FeatureFlag = require('Module:FeatureFlag')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Table = require('Module:Table')
local TypeUtil = require('Module:TypeUtil')

local DisplayUtil = {propTypes = {}, types = {}}

--[[
Checks that the props to be used by a display component satisfy type
constraints. Throws if it does not.

For performance reasons, type checking is disabled unless the force_type_check
feature flag is enabled via {{#vardefine:feature_force_type_check|1}}.

By default this only checks the contents of table properties up to 1 deep.
Specify options.maxDepth to increase the depth.
]]
DisplayUtil.assertPropTypes = function(props, propTypes, options)
	local typeCheckFeature = FeatureFlag.get('force_type_check')
	if not typeCheckFeature then
		return
	end

	options = options or {}

	local errors = TypeUtil.checkValue(
		props,
		TypeUtil.struct(propTypes),
		{
			maxDepth = options.maxDepth or 2,
			name = 'props',
		}
	)
	if #errors > 0 then
		error(table.concat(errors, '\n'), 2)
	end
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

--[[
Attempts to render a display component in the pure function style. If it fails,
then renders the Other component with the error instance.

The error is logged and stashed for display. The props of the original display
component is attached to the error.
]]
function DisplayUtil.tryOrElseLog(Component, props, Other)
	return Logic.tryOrElseLog(
		function() return Component(props) end,
		Other,
		function(error)
			error.header = 'Error occured in display component: (caught by DisplayUtil.tryOrElseLog)'
			error.props = props
			return error
		end
	)
end

--[[
Attempts to render a display component in the pure function style. Returns nil
upon failure.

The error is logged and stashed for display. The props of the display component
is attached to the error.
]]
DisplayUtil.tryOrLog = DisplayUtil.tryOrElseLog

-- Whether a value is a mediawiki html node.
local mwHtmlMetatable = FnUtil.memoize(function()
	return getmetatable(mw.html.create('div'))
end)
function DisplayUtil.isMwHtmlNode(x)
	return type(x) == 'table'
		and getmetatable(x) == mwHtmlMetatable()
end

--[[
Like Array.extendWith, except that mediawiki html nodes are not considered arrays.
]]
function DisplayUtil.extendWithArray(outs, ...)
	local inputs = Table.pack(...)
	for i = 1, inputs.n do
		local elem = inputs[i]
		if type(elem) == 'table'
			and not DisplayUtil.isMwHtmlNode(elem) then
			for _, innerElem in ipairs(elem) do
				table.insert(outs, innerElem)
			end
		elseif elem ~= nil then
			table.insert(outs, elem)
		end
	end
	return outs
end

--[[
Like Array.extend, except that mediawiki html nodes are not considered arrays.
]]
function DisplayUtil.extendArray(...)
	return DisplayUtil.extendWithArray({}, ...)
end

--[[
Like Array.flatten, except that mediawiki html nodes are not considered arrays.
]]
function DisplayUtil.flattenArray(elems)
	return DisplayUtil.extendArray(unpack(elems))
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

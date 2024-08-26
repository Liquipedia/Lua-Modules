---
-- @Liquipedia
-- wiki=commons
-- page=Module:DisplayUtil
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local FeatureFlag = require('Module:FeatureFlag')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
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
---@param props table
---@param propTypes table
---@param options {maxDepth: integer?}?
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

---Attempts to render a display component in the pure function style.
---The error is caught and displayed using classic error style.
---@param Component fun(props: table): Html
---@param props table
---@param other fun(error: Error): Html
---@return Html
function DisplayUtil.TryPureComponent(Component, props, other)
	return Logic.tryOrElseLog(
		function() return Component(props) end,
		other,
		function(error)
			error.header = 'Error occured in display component: (caught by DisplayUtil.TryPureComponent)'
			return error
		end
	)
end
DisplayUtil.tryOrLog = DisplayUtil.TryPureComponent
DisplayUtil.tryOrElseLog = DisplayUtil.TryPureComponent


---@alias OverflowModes 'ellipsis'|'wrap'|'hidden'
DisplayUtil.types.OverflowModes = TypeUtil.literalUnion('ellipsis', 'wrap', 'hidden')

---Specifies overflow behavior on a block element. mode can be 'ellipsis', 'wrap', or 'hidden'.
---@param node Html
---@param mode OverflowModes
---@return Html
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

---@param x any
---@return boolean
function DisplayUtil.isMwHtmlNode(x)
	return type(x) == 'table'
		and getmetatable(x) == mwHtmlMetatable()
end

---Like Array.flatten, except that mediawiki html nodes are not considered arrays.
---@generic T
---@param elems T[]
---@return T[]
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
---@param text string
---@return string
function DisplayUtil.removeLinkFromWikiLink(text)
	local textNoLink = text:gsub('link=[^|%]]*', 'link=')
	return textNoLink
end

return DisplayUtil

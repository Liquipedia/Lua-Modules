---
-- @Liquipedia
-- wiki=commons
-- page=Module:Error/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local ErrorExt = require('Module:Error/Ext')
local TypeUtil = require('Module:TypeUtil')

local ErrorDisplay = {types = {}, propTypes = {}}

-- Error instance
ErrorDisplay.types.Error = TypeUtil.struct{
	childErrors = TypeUtil.optional(TypeUtil.array(ErrorDisplay.types.Error)),
	header = 'string?',
	innerError = 'any',
	message = 'string',
	originalErrors = TypeUtil.optional(TypeUtil.array(ErrorDisplay.types.Error)),
	stacks = TypeUtil.optional(TypeUtil.array('string')),
}

ErrorDisplay.propTypes.Box = {
	hasDetails = 'boolean?',
	loggedInOnly = 'boolean?',
	text = 'string',
}

function ErrorDisplay.Box(props)
	local div = mw.html.create('div'):addClass('navigation-not-searchable ambox-wrapper')
		:addClass('ambox wiki-bordercolor-dark wiki-backgroundcolor-light')
		:addClass(props.loggedInOnly ~= false and 'show-when-logged-in' or nil)
		:addClass('ambox-red')

	local tbl = mw.html.create('table')
	local tr = tbl:tag('tr')
	tr:tag('td'):addClass('ambox-image')
		:wikitext('[[File:Emblem-important.svg|40px|link=]]')
	tr:tag('td'):addClass('ambox-text')
		:wikitext(props.text)
		:wikitext(props.hasDetails and ' (stack trace logged)' or nil)

	return div:node(tbl)
end

function ErrorDisplay.ErrorBox(error)
	return ErrorDisplay.Box({
		hasDetails = error.stacks ~= nil,
		text = tostring(error),
	})
end

--[[
Shows the message and stack trace of a lua error. Suitable for use in a popup.
]]
function ErrorDisplay.ErrorDetails(error)
	local errorDetailsNode = mw.html.create('div'):addClass('error-details')

	errorDetailsNode:tag('div'):addClass('error-details-text')
		:addClass('error')
		:css('font-weight', 'bold')
		:wikitext(error.header)
		:wikitext(error.message)

	local stackTraceString = ErrorExt.makeFullStackTrace(error)
	if stackTraceString ~= '' then
		errorDetailsNode:tag('div'):addClass('error-details-stacks')
			:wikitext(stackTraceString)
	end

	local extraPropsString = ErrorExt.printExtraProps(error)
	if extraPropsString then
		errorDetailsNode:tag('div'):addClass('error-details-additional-props')
			:wikitext(extraPropsString)
	end

	return errorDetailsNode
end

return ErrorDisplay

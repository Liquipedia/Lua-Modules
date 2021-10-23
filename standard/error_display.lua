---
-- @Liquipedia
-- wiki=commons
-- page=Module:Error/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local ErrorExt = require('Module:Error/Ext')
local ErrorStash = require('Module:Error/Stash')
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

ErrorDisplay.propTypes.StashedErrors = {
	limit = 'number?',
}

function ErrorDisplay.StashedErrors(props)
	local defaultLimit = 5
	local limit = props.limit or defaultLimit

	local errors = ErrorStash.retrieve()

	local boxesNode = mw.html.create('span'):addClass('stashed-errors')
	for index, error in ipairs(errors) do
		boxesNode:node(ErrorDisplay.ErrorBox(error))

		if index == limit and limit < #errors then
			local overflowNode = ErrorDisplay.Box({
				text = (#errors - limit) .. ' additional errors not shown',
			})
			boxesNode:node(overflowNode)
			break
		end
	end
	return boxesNode
end

-- Entry point of Template:StashedErrors
function ErrorDisplay.TemplateStashedErrors(frame)
	local args = Arguments.getArgs(frame)
	return ErrorDisplay.StashedErrors({
		limit = tonumber(args.limit),
	})
end

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

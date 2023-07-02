---
-- @Liquipedia
-- wiki=commons
-- page=Module:Error/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local ErrorExt = require('Module:Error/Ext')
local TypeUtil = require('Module:TypeUtil')

local ErrorDisplay = {types = {}, propTypes = {}}

---@param props {limit: integer?, errors: error[]}
---@return Html
function ErrorDisplay.ErrorList(props)
	local defaultLimit = 5
	local limit = props.limit or defaultLimit

	local boxesNode = mw.html.create('span'):addClass('stashed-errors')
	for index, error in ipairs(props.errors) do
		boxesNode:node(ErrorDisplay.ErrorBox(error))

		if index == limit and limit < #props.errors then
			local overflowNode = ErrorDisplay.Box{
				text = (#props.errors - limit) .. ' additional errors not shown',
			}
			boxesNode:node(overflowNode)
			return boxesNode
		end
	end

	return boxesNode
end

---Entry point of Template:StashedErrors
---@param frame Frame
---@return Html
function ErrorDisplay.TemplateStashedErrors(frame)
	local args = Arguments.getArgs(frame)
	return ErrorDisplay.ErrorList{
		errors = ErrorExt.Stash.retrieve(),
		limit = tonumber(args.limit),
	}
end

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

---@param props {hasDetails: boolean?, loggedInOnly: boolean?, text: string}
---@return Html
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

---@param error error
---@return Html
function ErrorDisplay.ErrorBox(error)
	return ErrorDisplay.Box{
		hasDetails = error.stacks ~= nil,
		text = tostring(error),
	}
end

---Shows the message and stack trace of a lua error. Suitable for use in a popup.
---@param error error
---@return Html
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

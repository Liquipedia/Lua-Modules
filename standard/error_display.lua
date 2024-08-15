---
-- @Liquipedia
-- wiki=commons
-- page=Module:Error/Display
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local ErrorExt = require('Module:Error/Ext')
local Json = require('Module:Json')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local ErrorDisplay = {types = {}, propTypes = {}}

local FILTERED_ERROR_STACK_ITEMS = {
	'^Module:ResultOrError:%d+: in function <Module:ResultOrError:%d+>$',
	'^%[C%]: in function \'xpcall\'$',
	'^Module:ResultOrError:%d+: in function \'try\'$',
}

---@param props {limit: integer?, errors: Error[]}
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

---@param error Error
---@return Html
function ErrorDisplay.ErrorBox(error)
	return ErrorDisplay.Box{
		hasDetails = error.stacks ~= nil,
		text = tostring(error),
	}
end

---Shows the message and stack trace of a lua error. Suitable for use in a popup.
---@param error Error
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

---Builds a JSON string for use by `liquipedia.customLuaErrors` JS module with `error()`.
---@param error Error
---@return string
function ErrorDisplay.ClassicError(error)
	local stackTrace = {}

	local processStackFrame = function(frame, frameIndex)
		if frameIndex == 1 and frame == '[C]: ?' then
			return
		end

		local stackEntry = {content = frame}
		local frameSplit = mw.text.split(frame, ':', true)
		if (frameSplit[1] == '[C]' or frameSplit[1] == '(tail call)') then
			stackEntry.prefix = frameSplit[1]
			stackEntry.content = mw.text.trim(table.concat(frameSplit, ':', 2))
		elseif frameSplit[1]:sub(1, 3) == 'mw.' then
			stackEntry.prefix = table.concat(frameSplit, ':', 1, 2)
			stackEntry.content =  table.concat(frameSplit, ':', 3)
		elseif frameSplit[1] == 'Module' then
			local wiki = not Page.exists(table.concat(frameSplit, ':', 1, 2)) and 'commons'
				or mw.text.split(mw.title.getCurrentTitle():canonicalUrl(), '/', true)[4] or 'commons'
			stackEntry.link = {wiki = wiki, title = table.concat(frameSplit, ':', 1, 2), ln = frameSplit[3]}
			stackEntry.prefix = table.concat(frameSplit, ':', 1, 3)
			stackEntry.content = table.concat(frameSplit, ':', 4)
		end

		table.insert(stackTrace, stackEntry)
	end

	Array.forEach(error.stacks or {}, function(stack)
		local stackFrames = mw.text.split(stack, '\n')
		stackFrames = Array.filter(
			Array.map(
				Array.sub(stackFrames, 2, #stackFrames),
				function(frame) return String.trim(frame) end
			),
			function(frame) return not Table.any(FILTERED_ERROR_STACK_ITEMS, function(_, filter)
				return string.find(frame, filter) ~= nil
			end) end
		)
		Array.forEach(stackFrames, processStackFrame)
	end)

	local errorSplit = mw.text.split(error.message, ':', true)
	local errorText
	if #errorSplit == 4 then
		errorText = string.format('Lua error in %s:%s at line %s:%s.', unpack(errorSplit))
	elseif #errorSplit > 4 then
		errorText = string.format('Lua error in %s:%s at line %s:%s', unpack(Array.sub(errorSplit, 1, 4)))
		errorText = errorText .. ':' .. table.concat(Array.sub(errorSplit, 5), ':') .. '.'
	else
		errorText = string.format('Lua error: %s.', error.message)
	end
	local jsonData = Json.stringify({
		errorShort = errorText,
		stackTrace = stackTrace,
	}, {asArray = true})
	return tostring(mw.html.create('div')
				:tag('strong'):addClass('error')
				:tag('span'):addClass('scribunto-error')
				:wikitext(jsonData):wikitext('.')
				:allDone())
end

return ErrorDisplay

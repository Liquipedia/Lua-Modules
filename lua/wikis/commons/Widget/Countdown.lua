---
-- @Liquipedia
-- page=Module:Widget/Countdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local StreamLinks = Lua.import('Module:Links/Stream')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local StreamsContainer = Lua.import('Module:Widget/Match/StreamsContainer')

---@class CountdownWidgetProps
---@field date string?
---@field timestamp integer?
---@field rawcountdown boolean?
---@field rawdatetime boolean?
---@field finished boolean?
---@field nostreams boolean?
---@field text string?
---@field separator string?
---@field format ('full'|'compact')?
---@field [string] string? stream

local CountdownWidget = {
	defaultProps = {
		format = 'full'
	}
}

---@param props CountdownWidgetProps
---@param hasStreams boolean
---@return VNode
function CountdownWidget.createWrapper(props, hasStreams)
	local classes = {'timer-object'}
	local attributes = {
		['data-format'] = props.format,
		['data-hasstreams'] = hasStreams and 'true' or nil,
		['data-countdown-end-text'] = props.text,
		['data-separator'] = props.separator,
	}
	if Logic.readBool(props.rawcountdown) then
		table.insert(classes, 'timer-object-countdown-only')
	end
	if Logic.readBool(props.rawdatetime) then
		table.insert(classes, 'timer-object-datetime-only')
	end

	-- Timestamp
	local timestamp = props.timestamp or
		(props.date:find('data%-tz="[%+%-]?%d') and DateExt.readTimestampOrNil(props.date)) or
		'error'
	attributes['data-timestamp'] = timestamp

	if Logic.readBool(props.finished) then
		attributes['data-finished'] = 'finished'
	end
	return Html.Span{
		classes = classes,
		attributes = attributes,
		children = props.date,
	}
end

---@param props CountdownWidgetProps
---@return {[string]: string[]}?
function CountdownWidget.readStreams(props)
	if Logic.readBool(props.finished) or Logic.readBool(props.nostreams) then
		return
	end
	local parsedStreams = StreamLinks.filterStreams(Table.filterByKey(props, function(key)
		return type(key) == 'string'
	end) --[[@as {string: string}]])
	if Logic.isDeepEmpty(parsedStreams) then
		return
	end
	return parsedStreams
end

---@param props CountdownWidgetProps
---@return VNode[]?
function CountdownWidget.render(props)
	if Logic.isEmpty(props.date) and not props.timestamp then
		return
	end
	local parsedStreams = CountdownWidget.readStreams(props)
	return {
		CountdownWidget.createWrapper(props, parsedStreams ~= nil),
		parsedStreams and StreamsContainer{
			buttonSize = 'xs',
			streams = parsedStreams,
		} or nil,
	}
end

return Component.component(CountdownWidget.render, CountdownWidget.defaultProps)

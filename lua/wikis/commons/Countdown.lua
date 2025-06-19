---
-- @Liquipedia
-- page=Module:Countdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local StreamLinks = Lua.import('Module:Links/Stream')

local Countdown = {}

---@param frame Frame
---@return string
function Countdown.create(frame)
	return Countdown._create(Arguments.getArgs(frame))
end

---@param args table
---@return string
function Countdown._create(args)
	args = args or {}
	if Logic.isEmpty(args.date) and not args.timestamp then
		return ''
	end

	local wrapper = mw.html.create('span')
		:addClass('timer-object')

	if Logic.readBool(args.rawcountdown) then
		wrapper:addClass('timer-object-countdown-only')
	end
	if Logic.readBool(args.rawdatetime) then
		wrapper:addClass('timer-object-datetime-only')
	end

	-- Timestamp
	local timestamp = args.timestamp or
		(args.date:find('data%-tz="[%+%-]?%d') and DateExt.readTimestampOrNil(args.date)) or
		'error'
	wrapper:attr('data-timestamp', timestamp)

	local streams
	if Logic.readBool(args.finished) then
		wrapper:attr('data-finished', 'finished')
	elseif not Logic.readBool(args.nostreams) then
		local streamArgs = Table.filterByKey(args, function(key)
			return type(key) == 'string'
		end) --[[@as {string: string}]]
		streams = StreamLinks.buildDisplays(StreamLinks.filterStreams(streamArgs))
	end
	if streams then
		streams = table.concat(streams, ' ')
		wrapper:attr('data-hasstreams', 'true')
	end

	if Logic.readBool(args.showCompleted) then
		wrapper:attr('data-show-completed', 'true')
	end

	if args.text then
		wrapper:attr('data-countdown-end-text', args.text)
	end
	if args.separator then
		wrapper:attr('data-separator', args.separator)
	end

	wrapper:wikitext(args.date)

	if Logic.isEmpty(streams) then
		return tostring(wrapper)
	end

	return tostring(mw.html.create()
		:node(wrapper)
		:wikitext(streams)
	)
end

return Countdown

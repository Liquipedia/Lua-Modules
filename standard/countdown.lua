---
-- @Liquipedia
-- wiki=commons
-- page=Module:Countdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local StreamLinks = Lua.import('Module:Links/Stream')

local NOW = os.time()

local Countdown = {}

---@param frame Frame
---@return string
function Countdown.create(frame)
	return Countdown._create(Arguments.getArgs(frame))
end

---@param args table
---@return string
function Countdown._create(args)
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

	local streams
	if Logic.readBool(args.finished) then
		wrapper:attr('data-finished', 'finished')
	elseif not Logic.readBool(args.nostreams) then
		streams = StreamLinks.display(StreamLinks.filterStreams(args), {addSpace = true})
	end

	-- Timestamp
	local timestamp = args.timestamp or DateExt.readTimestampOrNil(args.date) or 'error'
	wrapper:attr('data-timestamp', timestamp)

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

	local sep = Logic.isNumeric(timestamp) and NOW < timestamp + 43200
		and ' - ' or nil

	return tostring(mw.html.create()
		:node(wrapper)
		:wikitext(sep)
		:wikitext(streams)
	)
end

return Countdown

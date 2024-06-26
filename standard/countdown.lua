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
local StreamLinks = require('Module:Links/Stream')

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
	if Logic.readBool(args.finished) then
		wrapper:attr('data-finished', 'finished')
	else
		wrapper:attr('data-streams', StreamLinks.display(StreamLinks.filterStreams(args)))
	end

	-- Timestamp
	wrapper:attr('data-timestamp', args.timestamp or DateExt.readTimestampOrNil(args.date) or 'error')

	if args.text then
		wrapper:attr('data-countdown-end-text', args.text)
	end
	if args.separator then
		wrapper:attr('data-separator', args.separator)
	end

	wrapper:wikitext(args.date)

	return tostring(wrapper:done())
end

return Countdown

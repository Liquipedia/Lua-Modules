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
local Table = require('Module:Table')

local Countdown = {}

local CONVERT_TO_ATTRIBUTE = {
	afreeca = 'afreecatv',
	stream = 'tl'
}

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

	if args.rawcountdown then
		wrapper:addClass('timer-object-countdown-only')
	end
	if args.rawdatetime then
		wrapper:addClass('timer-object-datetime-only')
	end
	if args.finished and args.finished == 'true' then
		wrapper:attr('data-finished', 'finished')
	end

	-- Timestamp
	wrapper:attr('data-timestamp', args.timestamp or DateExt.readTimestampOrNil(args.date) or 'error')

	local hasEnglishStream = Table.any(args, function(key)
		return key:match('_en_') or Table.includes(StreamLinks.countdownPlatformNames, key)
	end)

	local newHosts = {}
	for rawHost, stream in Table.iter.spairs(args) do
		if #(mw.text.split(rawHost, '_', true)) == 3 then
			local streamKey = StreamLinks.StreamKey(rawHost)
			local platform = streamKey.platform
			if not newHosts[platform] then
				newHosts[platform] = {}
			end
			table.insert(newHosts[platform], (not hasEnglishStream or streamKey.languageCode == 'en') and stream or nil)
		end
	end

	for _, platformName in pairs(StreamLinks.countdownPlatformNames) do
		if type(newHosts[platformName]) ~= 'table' then
			newHosts[platformName] = {args[platformName], args[platformName .. 2]}
		end

		for index, stream in ipairs(newHosts[platformName]) do
			wrapper:attr(
				'data-stream-' .. (CONVERT_TO_ATTRIBUTE[platformName] or platformName) .. (index == 1 and '' or index),
				stream
			)
		end
	end

	--legacy???
	if args.pandatv then
		wrapper:attr('data-stream-pandatv', args.pandatv)
	end
	if args.play2live then
		wrapper:attr('data-stream-play2live', args.play2live)
	end
	if args.smashcast then
		wrapper:attr('data-stream-smashcast', args.smashcast)
	end

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

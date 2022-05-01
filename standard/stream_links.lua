---
-- @Liquipedia
-- wiki=commons
-- page=Module:Links/Stream
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
Module containing utility functions for streaming platforms.
]]
local StreamLinks = {}

local FeatureFlag = require('Module:FeatureFlag')
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Variables = require('Module:Variables')

--[[
List of streaming platforms supported in Module:Countdown. This is a subset of
the list in Module:Links
]]
StreamLinks.countdownPlatformNames = {
	'afreeca',
	'afreecatv',
	'bilibili',
	'cc163',
	'dailymotion',
	'douyu',
	'facebook',
	'huomao',
	'huya',
	'loco',
	'mildom',
	'nimo',
	'stream',
	'tl',
	'trovo',
	'twitch',
	'twitch2',
	'youtube',
}

--[[
Lookup table of allowed inputs that use a plattform with a different name
]]
StreamLinks.streamPlatformLookupNames = {
	twitch2 = 'twitch',
}

--[[
Extracts the streaming platform args from an argument table for use in
Module:Countdown.
]]
function StreamLinks.readCountdownStreams(args)
	local stream = {}
	for _, platformName in ipairs(StreamLinks.countdownPlatformNames) do
		stream[platformName] = args[platformName]
	end
	return stream
end

--[[
Resolves the value of a stream given the platform
]]
function StreamLinks.resolve(platformName, streamValue)
	local streamLink = mw.ext.StreamPage.resolve_stream(platformName, streamValue)

	return string.gsub(streamLink, 'Special:Stream/' .. platformName, '')
end

--[[
Builds a key for the Stream Key.

Format of a Stream Key is:
platform_languageCode_index
]]
function StreamLinks._buildKey(platform, languageCode, index)
	assert(Logic.isNotEmpty(platform), 'StreamLinks: Platform is required.')
	assert(Logic.isNotEmpty(languageCode), 'StreamLinks: Language Code is required.')
	assert(Logic.isNumeric(index), 'StreamLinks: Numeric Platform Index is required.')
	languageCode = languageCode:lower()
	index = tonumber(index)
	return platform .. "_" .. languageCode .. "_" .. index
end

--[[
Extracts the streaming platform args from an argument table or a nested stream table inside the arguments table.
Uses variable fallbacks and resolves stream redirects.
]]
function StreamLinks.processStreams(forwardedInputArgs)
	local streams = {}
	if type(forwardedInputArgs.stream) == 'table' then
		streams = forwardedInputArgs.stream
		forwardedInputArgs.stream = nil
	end

	for _, platformName in pairs(StreamLinks.countdownPlatformNames) do
		local streamValue = Logic.emptyOr(
			streams[platformName],
			forwardedInputArgs[platformName],
			Variables.varDefault(platformName)
		)

		if String.isNotEmpty(streamValue) then
			local platform = platformName
			local languageCode = 'en'
			local count = 1
			-- stream has no platform
			if platform ~= 'stream' then
				if StreamLinks.streamPlatformLookupNames[platform] then
					count = tonumber(platform:match('(%d+)$'))
					platform = StreamLinks.streamPlatformLookupNames[platform]
				end

				streamValue = StreamLinks.resolve(platform, streamValue)
			end

			if FeatureFlag.get('new_stream_format') then
				local key = StreamLinks._buildKey(platform, languageCode, count)
				streams[key] = streamValue
			end
			streams[platformName] = streamValue
		end
	end

	return streams
end

return StreamLinks

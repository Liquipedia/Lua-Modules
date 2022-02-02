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
	'pandatv',
	'play2live',
	'smashcast',
	'stream',
	'tl',
	'trovo',
	'twitch',
	'twitch2',
	'youtube',
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
Extracts the streaming platform args from an argument table or a nested stream table inside the arguments table.
Uses variable fallbacks and resolves stream redirects.
]]
function StreamLinks.processStreams(args)
	local streams = {}
	if type(args.stream) == 'table' then
		streams = args.stream
	end

	for _, platformName in pairs(StreamLinks.countdownPlatformNames) do
		-- stream has no platform and might be a table or a string
		if platformName == 'stream' then
			local streamValue = streams.stream
			if String.isEmpty(streamValue) and type(args.stream) == 'string' then
				streamValue = args.stream
			end
			if String.isEmpty(streamValue) then
				streamValue = Variables.varDefault(platformName)
			end
			if String.isNotEmpty(streamValue) then
				streams.stream = streamValue
			end
		else
			local streamValue = Logic.emptyOr(streams[platformName] or args[platformName], Variables.varDefault(platformName))

			-- twitch2 is not a platform but uses the twitch platform instead
			local lookUpPlatform = platformName
			if platformName == 'twitch2' then
				lookUpPlatform = 'twitch'
			end

			if String.isNotEmpty(streamValue) then
				streams[platformName] = StreamLinks.resolve(lookUpPlatform, streamValue)
			end
		end
	end

	return streams
end

return StreamLinks

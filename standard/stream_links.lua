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
Converts a key of new format to legacy format
]]
function StreamLinks.keyToLegacy(key)
	if String.isNotEmpty(key) then
		local splitKey = mw.text.split(key, '_', true)
		if #splitKey == 3 and Logic.isNumeric(splitKey[3]) then
			local platform = splitKey[3]
			local index = tonumber(splitKey[3])
			if index > 1 then
				platform = platform .. index
			end
			return platform
		end
	end
	return false, "StreamLinks.keyToLegacy: Invalid input"
end

--[[
Converts legacy input to a key of new format
]]
function StreamLinks.legacyToKey(platform)
	local languageCode = 'en'
	local index = 1
	for _, validPlatform in pairs(StreamLinks.countdownPlatformNames) do
		-- The intersection between countdownPlatformNames and streamPlatformLookupNames are not valid platforms.
		if not StreamLinks.streamPlatformLookupNames[validPlatform] then
			-- Let's find the actual platform of the input. (Eg. "twitch" in the input "twitch35")
			-- Offset will be the location of the last letter of the actual platform
			local _, offset = platform:find(validPlatform, 1, true)
			if offset then
				-- If there's more than just the platform name in the input means there's an index at the end
				if #platform > #validPlatform then
					index = tonumber(platform:sub(offset+1))
					platform = validPlatform
				end
				return StreamLinks._buildKey(platform, languageCode, index)
			end
		end
	end
	return false, "StreamLinks.legacyToKey: Invalid input"
end

--[[
Builds a key for the Stream Key.

Format of a Stream Key is:
platform_languageCode_index
]]
function StreamLinks._buildKey(platform, languageCode, index)
	assert(Logic.isNotEmpty(platform), 'StreamLinks._buildKey: Platform is required')
	assert(Logic.isNotEmpty(languageCode), 'StreamLinks._buildKey: Language Code is required')
	assert(Logic.isNumeric(index), 'StreamLinks._buildKey: Platform Index must be numeric')
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
			-- stream has no platform
			if platformName ~= 'stream' then
				local lookUpPlatform = StreamLinks.streamPlatformLookupNames[platformName] or platformName

				streamValue = StreamLinks.resolve(lookUpPlatform, streamValue)
			end

			if FeatureFlag.get('new_stream_format') then
				local key = StreamLinks.legacyToKey(platformName)
				streams[key] = streamValue
			end
			streams[platformName] = streamValue
		end
	end

	return streams
end

return StreamLinks

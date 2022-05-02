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

local Class = require('Module:Class')
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
				local key = StreamLinks.StreamKey(platformName):toString()
				streams[key] = streamValue
			end
			streams[platformName] = streamValue
		end
	end

	return streams
end

--- StreamKey Class
-- Contains the triplet that makes up a stream key
-- [platform, languageCode, index]
StreamLinks.StreamKey = Class.new(
	function (self, ...)
		self:new(...)
	end
)
local StreamKey = StreamLinks.StreamKey

function StreamKey:new(tbl, languageCode, index)
	local platform
	-- Input is another StreamKey - Make a copy
	if StreamKey._isStreamKey(tbl) then
		platform = tbl.platform
		languageCode = tbl.languageCode
		index = tbl.index
	-- Input is another table, assume format is {platform, languageCode, index}
	elseif type(tbl) == 'table' then
		platform, languageCode, index = unpack(tbl)
	-- All three parameters are supplied
	elseif languageCode and index then
		platform = tbl
	elseif type(tbl) == 'string' then
		local components = mw.text.split(tbl, '_', true)
		-- Input is in legacy format (eg. twitch2)
		if #components == 1 then
			platform, index = self:_fromLegacy(tbl)
			languageCode = 'en'
		-- Input is a StreamKey in string format
		elseif #components == 3 then
			platform, languageCode, index = unpack(components)
		end
	end

	self.platform = platform
	self.languageCode = languageCode
	self.index = tonumber(index)
	self:_isValid()
	self.languageCode = self.languageCode:lower()
end

function StreamKey:_fromLegacy(input)
	for _, platform in pairs(StreamLinks.countdownPlatformNames) do
		-- The intersection of values in countdownPlatformNames and keys in streamPlatformLookupNames
		-- are not valid platforms.
		if not StreamLinks.streamPlatformLookupNames[platform] then
			-- Check if this platform matches the input
			if string.find(input, platform, 1, true) then
				local index = 1
				-- If the input is longer than the platform, there's an index at the end
				-- e.g. twitch2
				if #input > #platform then
					index = tonumber(input:sub(#platform + 1))
				end
				return platform, index
			end
		end
	end
end

function StreamKey:toString()
	return self.platform .. '_' .. self.languageCode .. '_' .. self.index
end

function StreamKey:toLegacy()
	return self.platform .. (self.index > 1 and self.index or '')
end

function StreamKey:_isValid()
	assert(Logic.isNotEmpty(self.platform), 'StreamKey: Platform is required')
	assert(Logic.isNotEmpty(self.languageCode), 'StreamKey: Language Code is required')
	assert(Logic.isNumeric(self.index), 'StreamKey: Platform Index must be numeric')
	return true
end

function StreamKey._isStreamKey(value)
	if type(value) == 'table' and type(value.is_a) == 'function' and value:is_a(StreamKey) then
		return true
	end
	return false
end
StreamKey.__tostring = StreamKey.toString

return StreamLinks

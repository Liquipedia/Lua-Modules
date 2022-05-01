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


local StreamKey = Class.new(
	function(self, ...)
		self:new(...)
	end
)

function StreamKey:new(tbl, languageCode, index)
	local platform
	if StreamKey._isStreamKey(tbl) then
		platform = tbl.platform
		languageCode = tbl.languageCode
		index = tbl.index
	elseif type(tbl) == 'table' then
		platform, languageCode, index = unpack(tbl)
	elseif languageCode and index then
		platform = tbl
	elseif type(tbl) == 'string' then
		local components = mw.text.split(tbl, '_', true)
		if #components == 1 then
			platform, languageCode, index = self:_fromLegacy(tbl)
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

function StreamKey:_fromLegacy(platform)
	local languageCode = 'en'
	for _, validPlatform in pairs(StreamLinks.countdownPlatformNames) do
		-- The intersection between countdownPlatformNames and streamPlatformLookupNames are not valid platforms.
		if not StreamLinks.streamPlatformLookupNames[validPlatform] then
			-- Let's find the actual platform of the input. (Eg. "twitch" in the input "twitch35")
			-- Offset will be the location of the last letter of the actual platform
			local _, offset = platform:find(validPlatform, 1, true)
			if offset then
				local index
				-- If there's more than just the platform name in the input means there's an index at the end
				if #platform > #validPlatform then
					index = tonumber(platform:sub(offset+1))
				else
					index = 1
				end
				return validPlatform, languageCode, index
			end
		end
	end
end

function StreamKey:toString()
	return self.platform .. "_" .. self.languageCode .. "_" .. self.index
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
StreamLinks.StreamKey = StreamKey

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
				local key = StreamKey(platformName):toString()
				streams[key] = streamValue
			end
			streams[platformName] = streamValue
		end
	end

	return streams
end

return StreamLinks

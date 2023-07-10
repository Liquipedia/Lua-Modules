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
local Logic = require('Module:Logic')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
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
	'youtube',
}

--[[
Lookup table of allowed inputs that use a plattform with a different name
]]
StreamLinks.streamPlatformLookupNames = {
	twitch2 = 'twitch',
}

---Extracts the streaming platform args from an argument table for use in Module:Countdown.
---@param args {[string]: string}
---@return table
function StreamLinks.readCountdownStreams(args)
	local stream = {}
	for _, platformName in ipairs(StreamLinks.countdownPlatformNames) do
		stream[platformName] = args[platformName]
	end
	return stream
end

---Resolves the value of a stream given the platform
---@param platformName string
---@param streamValue string
---@return string
function StreamLinks.resolve(platformName, streamValue)
	local streamLink = mw.ext.StreamPage.resolve_stream(platformName, streamValue)

	return (string.gsub(streamLink, 'Special:Stream/' .. platformName, ''))
end

--[[
Extracts the streaming platform args from an argument table or a nested stream table inside the arguments table.
Uses variable fallbacks and resolves stream redirects.
]]
---@param forwardedInputArgs {[string]: string|{[string]: string}}
---@return table
function StreamLinks.processStreams(forwardedInputArgs)
	local streams = {}
	if type(forwardedInputArgs.stream) == 'table' then
		streams = forwardedInputArgs.stream --[[@as {[string]: string}]]
		forwardedInputArgs.stream = nil
	end

	local processedStreams = {}
	for _, platformName in pairs(StreamLinks.countdownPlatformNames) do
		local findStreamValues = function(key) return key:match('^' .. platformName) end

		local streamValues = Table.merge(
			Table.filterByKey(forwardedInputArgs, findStreamValues),
			Table.filterByKey(streams, findStreamValues)
		)

		if Table.isEmpty(streamValues) then
			streamValues = {[platformName] = Variables.varDefault(platformName)}
		end 

		Table.mergeInto(processedStreams, StreamLinks._processStreamsOfPlatform(streamValues, platformName))
	end

	return processedStreams
end

function StreamLinks._processStreamsOfPlatform(streamValues, platformName)
	local platformStreams = {}
	local legacyStreams = {}
	local enCounter = 0

	for key, streamValue in Table.iter.spairs(streamValues) do
		if platformName ~= 'stream' then
			streamValue = StreamLinks.resolve(platformName, streamValue)
		end

		-- legacy key
		if key:match('^' .. platformName .. '%d*$') then
			table.insert(legacyStreams, streamValue)
		elseif key:match('^' .. platformName .. '_%a+_%d+') then
			local streamKey = StreamLinks.StreamKey(key)
			if streamKey.languageCode == 'en' then
				enCounter = enCounter + 1
			end
			platformStreams[streamKey:toString()] = streamValue
		end
	end

	for _, streamValue in ipairs(legacyStreams) do
		if not Table.includes(platformStreams, streamValue) then
			enCounter = enCounter + 1
			local streamKey = StreamLinks.StreamKey(platformName, 'en', enCounter):toString()
			platformStreams[streamKey] = streamValue
			platformStreams[platformName] = streamValue -- Legacy
		end
	end

	return platformStreams
end

--- StreamKey Class
-- Contains the triplet that makes up a stream key
-- [platform, languageCode, index]
---@class StreamKey
---@operator call(...): StreamKey
---@field platform string
---@field languageCode string
---@field index integer
---@field is_a function
StreamLinks.StreamKey = Class.new(
	function (self, ...)
		self:new(...)
	end
)
local StreamKey = StreamLinks.StreamKey

---@param tbl string
---@param languageCode string
---@param index integer
---@overload fun(self, tbl: StreamKey): StreamKey
---@overload fun(self, tbl: string): StreamKey
function StreamKey:new(tbl, languageCode, index)
	local platform
	-- Input is another StreamKey - Make a copy
	if StreamKey._isStreamKey(tbl) then
		platform = tbl.platform
		languageCode = tbl.languageCode
		index = tbl.index
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

	self.platform = platform --[[@as string]]
	self.languageCode = languageCode --[[@as string]]
	self.index = tonumber(index) --[[@as integer]]
	self:_isValid()
	self.languageCode = self.languageCode:lower()
end

---@param input string
---@return string?, integer?
function StreamKey:_fromLegacy(input)
	for _, platform in pairs(StreamLinks.countdownPlatformNames) do
		-- The intersection of values in countdownPlatformNames and keys in streamPlatformLookupNames
		-- are not valid platforms. E.g. "twitch2" is not a valid platform.
		if not StreamLinks.streamPlatformLookupNames[platform] then
			-- Check if this platform matches the input
			if string.find(input, platform .. '%d-$') then
				local index = 1
				-- If the input is longer than the platform, there's an index at the end
				-- Eg. In "twitch2", the 2 would the index.
				if #input > #platform then
					index = tonumber(input:sub(#platform + 1)) --[[@as integer]]
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
	-- Return twitch instead of twitch1
	if self.index == 1 then
		return self.platform
	end
	return self.platform .. self.index
end

function StreamKey:_isValid()
	assert(Logic.isNotEmpty(self.platform), 'StreamKey: Platform is required')
	assert(Logic.isNotEmpty(self.languageCode), 'StreamKey: Language Code is required')
	assert(Logic.isNumeric(self.index), 'StreamKey: Platform Index must be numeric')
	return true
end

---@param value StreamKey
---@return true
---@overload fun(value: any): false
function StreamKey._isStreamKey(value)
	if type(value) == 'table' and type(value.is_a) == 'function' and value:is_a(StreamKey) then
		return true
	end
	return false
end
StreamKey.__tostring = StreamKey.toString

return StreamLinks

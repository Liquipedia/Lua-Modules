---
-- @Liquipedia
-- page=Module:Links/Stream
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
Module containing utility functions for streaming platforms.
]]
local StreamLinks = {}

local Array = require('Module:Array')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Page = require('Module:Page')
local PageVariableNamespace = require('Module:PageVariableNamespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local streamVars = PageVariableNamespace('StreamCache')

local TLNET_STREAM = 'stream'

--List of streaming platforms supported in Module:Countdown.
StreamLinks.countdownPlatformNames = {
	'twitch',
	'youtube',
	'kick',
	'afreeca',
	'bilibili',
	'cc',
	'dailymotion',
	'douyu',
	'facebook',
	'huomao',
	'huya',
	'loco',
	'mildom',
	'nimo',
	'tl',
	'trovo',
	TLNET_STREAM,
}

local PLATFORM_TO_SPECIAL_PAGE = {
	afreeca = 'afreecatv',
	cc = 'cc163',
}

---@param key string
---@return boolean
---@overload fun(key: any): false
function StreamLinks.isStream(key)
	if type(key) ~= 'string' then return false end

	return Array.any(StreamLinks.countdownPlatformNames, function(platform)
		return String.startsWith(key, platform)
	end)
end

---Extracts the streaming platform args from an argument table for use in Module:Countdown.
---@param args {[string]: string}
---@return table
function StreamLinks.readCountdownStreams(args)
	return Table.filterByKey(args, StreamLinks.isStream)
end

---Resolves the value of a stream given the platform
---@param platformName string
---@param streamValue string
---@return string
function StreamLinks.resolve(platformName, streamValue)
	platformName = StreamLinks.resolvePlatform(platformName)

	local cachedLink = streamVars:get(platformName .. '_' .. streamValue)
	if cachedLink then
		return cachedLink
	end

	local streamLink = mw.ext.StreamPage.resolve_stream(platformName, streamValue)
	local cleanedStreamLink = string.gsub(streamLink, 'Special:Stream/' .. platformName, '')
	streamVars:set(platformName .. '_' .. streamValue, cleanedStreamLink)

	return cleanedStreamLink
end

---@param platform string
---@return string
function StreamLinks.resolvePlatform(platform)
	return PLATFORM_TO_SPECIAL_PAGE[platform] or platform
end

--[[
Extracts the streaming platform args from an argument table or a nested stream table inside the arguments table.
Uses variable fallbacks and resolves stream redirects.
]]
---@param forwardedInputArgs table
---@return table
function StreamLinks.processStreams(forwardedInputArgs)
	local streams = {}
	if type(forwardedInputArgs.stream) == 'table' then
		streams = forwardedInputArgs.stream
		forwardedInputArgs.stream = nil
	end

	streams = Table.merge(
		Table.filterByKey(forwardedInputArgs, StreamLinks.isStream),
		Table.filterByKey(streams, StreamLinks.isStream)
	)

	local processedStreams = {}
	Array.forEach(StreamLinks.countdownPlatformNames, function(platformName)
		Table.mergeInto(processedStreams, StreamLinks._processStreamsOfPlatform(streams, platformName))
	end)

	return processedStreams
end

---@param streamValues {[string]: string}
---@param platformName string
---@return {[string]: string}
function StreamLinks._processStreamsOfPlatform(streamValues, platformName)
	local platformStreams = {}
	local legacyStreams = {}
	local enCounter = 0

	for key, streamValue in Table.iter.spairs(streamValues) do
		if platformName ~= TLNET_STREAM then
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

	if Logic.isEmpty(platformStreams) then
		platformStreams = {[platformName] = Variables.varDefault(platformName)}
	end

	return platformStreams
end

---@param platform string
---@param streamValue string
---@return string?
function StreamLinks.displaySingle(platform, streamValue)
	local icon = '<i class="lp-icon lp-icon-21 lp-' .. platform .. '"></i>'
	if platform == TLNET_STREAM then
		return Page.makeExternalLink(icon, 'https://tl.net/video/streams/' .. streamValue)
	end

	local streamLink = StreamLinks.resolve(platform, streamValue)
	if not streamLink then return nil end

	platform = StreamLinks.resolvePlatform(platform)

	return Page.makeInternalLink({}, icon, 'Special:Stream/' .. platform .. '/' .. streamValue)
end

---@param streams {string: string[]}
---@return string[]?
function StreamLinks.buildDisplays(streams)
	local displays = {}
	Array.forEach(StreamLinks.countdownPlatformNames, function(platform)
		Array.forEach(streams[platform] or {}, function(streamValue)
			table.insert(displays, StreamLinks.displaySingle(platform, streamValue))
		end)
	end)
	return Table.isNotEmpty(displays) and displays or nil
end

---Filter non-english streams if english streams exists
---@param streamsInput {string: string}
---@return {string: string[]}
function StreamLinks.filterStreams(streamsInput)
	local hasEnglishStream = Table.any(streamsInput, function(key)
		return key:match('_en_') or Table.includes(StreamLinks.countdownPlatformNames, key)
	end)

	local streams = {}
	for rawHost, stream in Table.iter.spairs(streamsInput) do
		if #(mw.text.split(rawHost, '_', true)) == 3 then
			local streamKey = StreamLinks.StreamKey(rawHost)
			local platform = streamKey.platform
			if not streams[platform] then
				streams[platform] = {}
			end
			table.insert(streams[platform], (not hasEnglishStream or streamKey.languageCode == 'en') and stream or nil)
		end
	end

	Array.forEach(StreamLinks.countdownPlatformNames, function(platformName)
		local stream = streamsInput[platformName]
		if type(streams[platformName]) == 'table' or String.isEmpty(stream) then return end
		streams[platformName] = {stream, streamsInput[platformName .. 2]}
	end)

	return streams
end

--- StreamKey Class
-- Contains the triplet that makes up a stream key
-- [platform, languageCode, index]
---@class StreamKey: BaseClass
---@operator call(...): StreamKey
---@field platform string
---@field languageCode string
---@field index integer
local StreamKey = Class.new(
	function (self, ...)
		self:new(...)
	end
)
StreamLinks.StreamKey = StreamKey

---@overload fun(self, tbl: string, languageCode: string, index: integer): StreamKey
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
		---@cast tbl -StreamKey
		platform = tbl
	elseif type(tbl) == 'string' then
		local components = mw.text.split(tbl, '_', true)
		-- Input is in legacy format (eg. twitch2)
		if #components == 1 then
			platform, index = self:_fromLegacy(tbl)
			languageCode = 'en'
		-- Input is a StreamKey in string format
		elseif #components == 3 then
			local stringIndex
			platform, languageCode, stringIndex = unpack(components)
			index = tonumber(stringIndex) --[[@as integer]]
		end
	end

	self.platform = platform
	self.languageCode = languageCode
	self.index = tonumber(index) --[[@as integer]]
	self:_isValid()
	self.languageCode = self.languageCode:lower()
end

---@param input string
---@return string, integer
function StreamKey:_fromLegacy(input)
	for _, platform in pairs(StreamLinks.countdownPlatformNames) do
		if string.find(input, platform .. '%d-$') then
			local index = 1
			-- If the input is longer than the platform, there's an index at the end
			-- Eg. In "twitch2", the 2 would be the index.
			if #input > #platform then
				index = tonumber(input:sub(#platform + 1)) or index
				assert(index, '"' .. input .. '" is not a supported stream key')
			end
			return platform, index
		end
	end
	error('"' .. input .. '" is not a supported stream key')
end

---@return string
function StreamKey:toString()
	return self.platform .. '_' .. self.languageCode .. '_' .. self.index
end

---@return string
function StreamKey:toLegacy()
	-- Return twitch instead of twitch1
	if self.index == 1 then
		return self.platform
	end
	return self.platform .. self.index
end

---@return boolean
function StreamKey:_isValid()
	assert(Logic.isNotEmpty(self.platform), 'StreamKey: Platform is required')
	assert(Logic.isNotEmpty(self.languageCode), 'StreamKey: Language Code is required')
	assert(Logic.isNumeric(self.index), 'StreamKey: Platform Index must be numeric')
	return true
end

---@overload fun(value: StreamKey): true
---@overload fun(value: any): false
function StreamKey._isStreamKey(value)
	return Class.instanceOf(value, StreamKey)
end
StreamKey.__tostring = StreamKey.toString

return StreamLinks

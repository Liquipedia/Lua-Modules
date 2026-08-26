---
-- @Liquipedia
-- page=Module:Widget/Match/StreamsContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local StreamLinks = Lua.import('Module:Links/Stream')

local Component = Lua.import('Module:Widget/Component')
local MatchStream = Lua.import('Module:Widget/Match/Stream')

---@class MatchStreamsContainerProps
---@field streams table
---@field maxStreams integer?
---@field matchIsLive boolean?
---@field growButtons boolean?
---@field buttonSize 'xs'|'sm'|'md'|'lg'?

local defaultProps = {
	matchIsLive = true,
	buttonSize = 'sm',
}

---@param props MatchStreamsContainerProps
---@return VNode?
local function MatchStreamsContainer(props)
	local streams = props.streams
	if not streams then
		return nil
	end

	local processedStreams = Array.flatMap(StreamLinks.countdownPlatformNames, function(platform)
		return Array.map(streams[platform] or {}, function(stream)
			return {platform = platform, stream = stream}
		end)
	end)

	local numberOfStreams = #processedStreams
	if numberOfStreams == 0 then
		return nil
	end

	if props.maxStreams and numberOfStreams > props.maxStreams then
		processedStreams = Array.sub(processedStreams, 1, props.maxStreams)
	end

	return Array.map(processedStreams, function(stream)
		return MatchStream{
			platform = stream.platform,
			stream = stream.stream,
			matchIsLive = props.matchIsLive,
			grow = props.growButtons,
			buttonSize = props.buttonSize,
		}
	end)
end

return Component.component(MatchStreamsContainer, defaultProps)

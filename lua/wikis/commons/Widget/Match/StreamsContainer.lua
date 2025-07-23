---
-- @Liquipedia
-- page=Module:Widget/Match/StreamsContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local StreamLinks = Lua.import('Module:Links/Stream')

local Widget = Lua.import('Module:Widget')
local MatchStream = Lua.import('Module:Widget/Match/Stream')

---@class MatchStreamsContainer: Widget
---@operator call(table): MatchStreamsContainer
local MatchStreamsContainer = Class.new(Widget)
MatchStreamsContainer.defaultProps = {
	callToActionLimit = 0,
	matchIsLive = true,
}

---@return Widget?
function MatchStreamsContainer:render()
	local streams = self.props.streams
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

	local useCallToAction = numberOfStreams <= self.props.callToActionLimit

	return Array.map(processedStreams, function(stream)
		return MatchStream{
			platform = stream.platform,
			stream = stream.stream,
			callToAction = useCallToAction,
			matchIsLive = self.props.matchIsLive,
		}
	end)
end

return MatchStreamsContainer

---
-- @Liquipedia
-- page=Module:Widget/Match/Stream
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local StreamLinks = Lua.import('Module:Links/Stream')

local Widget = Lua.import('Module:Widget')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Image')

local TLNET_STREAM = 'stream'
local CTA_TEXT = '${icon} Watch on ${platform}'

---@class MatchStream: Widget
---@operator call(table): MatchStream
local MatchStream = Class.new(Widget)
MatchStream.defaultProps = {
	callToAction = false,
}

---@return Widget?
function MatchStream:render()
	local platform, stream = self.props.platform, self.props.stream

	if not platform or not stream then
		return nil
	end

	local icon = Icon{iconName = platform}

	local link, linkType
	if platform == TLNET_STREAM then
		link = 'https://tl.net/video/streams/' .. stream
		linkType = 'external'
	else
		local streamLink = StreamLinks.resolve(platform, stream)
		if not streamLink then return nil end

		link = 'Special:Stream/' .. StreamLinks.resolvePlatform(platform) .. '/' .. stream
		linkType = 'internal'
	end

	return Button{
		linktype = linkType,
		link = link,
		grow = self.props.callToAction,
		children = self.props.callToAction and String.interpolate(CTA_TEXT, { icon = icon, platform = platform }) or icon,
		variant = 'tertiary',
		size = 'sm',
	}
end

return MatchStream

---
-- @Liquipedia
-- page=Module:Widget/Match/Stream
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local I18n = Lua.import('Module:I18n')
local StreamLinks = Lua.import('Module:Links/Stream')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local TLNET_STREAM = 'stream'

---@class MatchStream: Widget
---@operator call(table): MatchStream
local MatchStream = Class.new(Widget)
MatchStream.defaultProps = {
	matchIsLive = true,
}

---@return Widget?
function MatchStream:render()
	local platform, stream = self.props.platform, self.props.stream

	if not platform or not stream then
		return nil
	end

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

	local CTA_Text
	if self.props.matchIsLive then
		CTA_Text = I18n.translate('matchstream-watch-live')
	else
		CTA_Text = I18n.translate('matchstream-watch-upcoming')
	end

	return Button{
		linktype = linkType,
		link = link,
		children = HtmlWidgets.Fragment{children = {
			Icon{iconName = platform},
			HtmlWidgets.Span{
				classes = {'match-button-cta-text'},
				children = CTA_Text,
			},
		}},
		variant = 'tertiary',
		size = 'sm',
	}
end

return MatchStream

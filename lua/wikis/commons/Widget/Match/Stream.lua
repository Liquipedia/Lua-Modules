---
-- @Liquipedia
-- page=Module:Widget/Match/Stream
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local I18n = Lua.import('Module:I18n')
local StreamLinks = Lua.import('Module:Links/Stream')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Button = Lua.import('Module:Widget/Basic/Button')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local TLNET_STREAM = 'stream'

---@class MatchStreamProps
---@field platform string
---@field stream string
---@field matchIsLive boolean?
---@field buttonSize 'xs'|'sm'|'md'|'lg'?
---@field grow boolean?

local defaultProps = {
	matchIsLive = true,
	buttonSize = 'sm',
}

---@param props MatchStreamProps
---@return VNode?
local function MatchStream(props)
	local platform, stream = props.platform, props.stream

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
	if props.matchIsLive then
		CTA_Text = I18n.translate('matchstream-watch-live')
	else
		CTA_Text = I18n.translate('matchstream-watch-upcoming')
	end

	return Button{
		linktype = linkType,
		link = link,
		children = {
			Icon{iconName = platform},
			Html.Span{
				classes = {'match-button-cta-text'},
				children = CTA_Text,
			},
		},
		variant = 'secondary',
		size = props.buttonSize,
		grow = props.grow,
	}
end

return Component.component(MatchStream, defaultProps)

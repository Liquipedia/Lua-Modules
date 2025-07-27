---
-- @Liquipedia
-- page=Module:Widget/Match/ButtonBar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local StreamLinks = Lua.import('Module:Links/Stream')
local VodLink = Lua.import('Module:VodLink')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local StreamsContainer = Lua.import('Module:Widget/Match/StreamsContainer')
local MatchPageButton = Lua.import('Module:Widget/Match/PageButton')
local Button = Lua.import('Module:Widget/Basic/Button')
local ImageIcon = Lua.import('Module:Widget/Image/Icon/Image')

local SHOW_STREAMS_WHEN_LESS_THAN_TO_LIVE = 2 * 60 * 60 -- 2 hours in seconds

---@class MatchButtonBarProps
---@field match MatchGroupUtilMatch
---@field showVods boolean?
---@field buttonStyle? 'primary' | 'secondary'

---@class MatchButtonBar: Widget
---@operator call(MatchButtonBarProps): MatchButtonBar
---@field props MatchButtonBarProps
local MatchButtonBar = Class.new(Widget)
MatchButtonBar.defaultProps = {
	showVods = true,
	buttonType = 'secondary',
}

---@return Widget?
function MatchButtonBar:render()
	local match = self.props.match
	if not match then
		return nil
	end

	local displayVods = match.phase == 'finished' and self.props.showVods
	local displayStreams = match.phase == 'ongoing'

	-- TODO: This logic is duplicated in PageButton, and should be refactored.
	-- Show streams also for the last period before going live
	if match.phase == 'upcoming' and match.timestamp and
		os.difftime(match.timestamp, DateExt.getCurrentTimestamp()) < SHOW_STREAMS_WHEN_LESS_THAN_TO_LIVE then

		displayStreams = true
	end

	---@param vod string?
	---@param index integer?
	---@return Widget?
	local makeVodButton = function(vod, index)
		if Logic.isEmpty(vod) then
			return nil
		end
		---@cast vod -nil
		return Button{
			linktype = 'external',
			title = VodLink.getTitle(index),
			variant = 'tertiary',
			link = vod,
			size = 'sm',
			classes = {'vodlink'},
			children = {
				ImageIcon{imageLight = VodLink.getIcon(index)},
				HtmlWidgets.Span{
					classes = {'match-button-cta-text'},
					children = VodLink.getTitle(index),
				},
			},
		}
	end

	return HtmlWidgets.Div{
		classes = {'match-info-links'},
		children = WidgetUtil.collect(
			MatchPageButton{
				match = match,
				buttonType = self.props.buttonType,
			},
			displayStreams and StreamsContainer{
				streams = StreamLinks.filterStreams(match.stream),
				matchIsLive = match.phase == 'ongoing',
			} or nil,
			displayVods and makeVodButton(match.vod) or nil
		)
	}
end

return MatchButtonBar

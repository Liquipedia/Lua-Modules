---
-- @Liquipedia
-- page=Module:Widget/Match/ButtonBar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info')
local Logic = Lua.import('Module:Logic')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
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

---@class MatchButtonBar: Widget
---@operator call(MatchButtonBarProps): MatchButtonBar
---@field props MatchButtonBarProps
local MatchButtonBar = Class.new(Widget)
MatchButtonBar.defaultProps = {
	showVods = true,
}

---@return Widget?
function MatchButtonBar:render()
	local match = self.props.match
	if not match then
		return nil
	end
	local matchPhase = MatchGroupUtil.computeMatchPhase(match)

	local displayMatchPage = matchPhase ~= 'upcoming' and Info.config.match2.matchPage
	local displayVods = matchPhase == 'finished' and self.props.showVods
	local displayStreams = matchPhase == 'ongoing'
	-- Show streams also for the last period before going live
	if matchPhase == 'upcoming' and match.timestamp and
		os.difftime(match.timestamp, DateExt.getCurrentTimestamp()) < SHOW_STREAMS_WHEN_LESS_THAN_TO_LIVE then

		displayStreams = true
	end

	---@param vod string?
	---@param index integer?
	---@param callToAction boolean
	---@return Widget?
	local makeVodButton = function(vod, index, callToAction)
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
			grow = callToAction,
			classes = {'vodlink'},
			children = {
				ImageIcon{imageLight = VodLink.getIcon(index)},
				callToAction and ' ' or nil,
				callToAction and VodLink.getTitle(index) or nil,
			},
		}
	end

	-- Original Match Id must be used to link match page if it exists.
	-- It can be different from the matchId when shortened brackets are used.
	local matchId = match.extradata.originalmatchid or match.matchId
	local matchPageButton = MatchPageButton{
		matchId = matchId,
		hasMatchPage = Logic.isNotEmpty(match.bracketData.matchPage),
	}

	return HtmlWidgets.Div{
		classes = {'match-info-links'},
		children = WidgetUtil.collect(
			displayMatchPage and matchPageButton or nil,
			displayStreams and StreamsContainer{
				streams = StreamLinks.filterStreams(match.stream),
				callToActionLimit = displayMatchPage and 0 or 2,
			} or nil,
			displayVods and makeVodButton(match.vod, nil, not displayMatchPage) or nil
		)
	}
end

return MatchButtonBar

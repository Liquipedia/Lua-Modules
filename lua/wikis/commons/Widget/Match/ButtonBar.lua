---
-- @Liquipedia
-- page=Module:Widget/Match/ButtonBar
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Logic = Lua.import('Module:Logic')
local StreamLinks = Lua.import('Module:Links/Stream')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local StreamsContainer = Lua.import('Module:Widget/Match/StreamsContainer')
local VodsDropdownButton = Lua.import('Module:Widget/Match/VodsDropdownButton')
local MatchPageButton = Lua.import('Module:Widget/Match/PageButton')
local VodButton = Lua.import('Module:Widget/Match/VodButton')
local Collapsible = Lua.import('Module:Widget/GeneralCollapsible/Default')

local SHOW_STREAMS_WHEN_LESS_THAN_TO_LIVE = 2 * 60 * 60 -- 2 hours in seconds

---@class MatchButtonBarProps
---@field match MatchGroupUtilMatch
---@field showVods boolean?
---@field variant? 'primary' | 'secondary'

---@class MatchButtonBar: Widget
---@operator call(MatchButtonBarProps): MatchButtonBar
---@field props MatchButtonBarProps
local MatchButtonBar = Class.new(Widget)
MatchButtonBar.defaultProps = {
	showVods = true,
	variant = 'secondary',
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
	elseif match.phase == 'upcoming' and self.props.variant == 'primary' then
		displayStreams = true
	end

	local makeVodDTO = function(vod, type, number)
		if not vod then
			return
		end
		return {
			vod = vod,
			type = type,
			number = number,
		}
	end

	local makeVodDTOs = function()
		local gameVods = Array.map(match.games, function(game, index)
			if Logic.isEmpty(game.vod) then
				return nil
			end
			return makeVodDTO(game.vod, 'game', index)
		end)
		local matchVod = makeVodDTO(match.vod, 'match')

		if #gameVods == 0 then
			return {matchVod}
		else
			return gameVods
		end
	end

	local vods = makeVodDTOs()
	local makeDropdownForVods = displayVods and #vods > 1
	local showInlineVods = displayVods and #vods == 1
	local standardBar = HtmlWidgets.Div{
		classes = {'match-info-links'},
		children = WidgetUtil.collect(
			MatchPageButton{
				match = match,
				buttonType = self.props.variant,
			},
			displayStreams and StreamsContainer{
				streams = StreamLinks.filterStreams(match.stream),
				matchIsLive = match.phase == 'ongoing',
			} or nil,
			makeDropdownForVods and VodsDropdownButton{count = #vods} or nil,
			showInlineVods and VodButton{vodLink = vods[1].vod} or nil
		)
	}

	if not makeDropdownForVods then
		return standardBar
	end

	return Collapsible{
		titleWidget = makeDropdownForVods,
		shouldCollapse = true,
		collapseAreaClasses = {'match-info-vods-area'},
		children = displayVods and Array.Map(vods, function(vod)
			return VodButton{vodLink = vod.vod, gameNumber = vod.number, showText = #vods < 4, variant = 'dropdown'}
		end) or nil,
	}
end

return MatchButtonBar

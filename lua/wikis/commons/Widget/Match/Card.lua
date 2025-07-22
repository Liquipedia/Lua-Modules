---
-- @Liquipedia
-- page=Module:Widget/Match/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Info = Lua.import('Module:Info')
local Logic = Lua.import('Module:Logic')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local StreamLinks = Lua.import('Module:Links/Stream')
local Tournament = Lua.import('Module:Tournament')
local VodLink = Lua.import('Module:VodLink')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchHeader = Lua.import('Module:Widget/Match/Header')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')
local MatchPageButton = Lua.import('Module:Widget/Match/PageButton')
local Button = Lua.import('Module:Widget/Basic/Button')
local ImageIcon = Lua.import('Module:Widget/Image/Icon/Image')
local StreamsContainer = Lua.import('Module:Widget/Match/StreamsContainer')

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'
local SHOW_STREAMS_WHEN_LESS_THAN_TO_LIVE = 2 * 60 * 60 -- 2 hours in seconds

---@class MatchCardProps
---@field match MatchGroupUtilMatch
---@field onlyHighlightOnValue string?
---@field hideTournament boolean?
---@field displayGameIcons boolean?

---@class MatchCard: Widget
---@operator call(MatchCardProps): MatchCard
---@field props MatchCardProps
local MatchCard = Class.new(Widget)
MatchCard.defaultProps = {
	hideTournament = false, -- Hide the tournament and stage
	displayGameIcons = false, -- Display the game icon in the tournament title
	onlyHighlightOnValue = nil, -- Only highlight if the publishertier has this value
}

---@return Widget?
function MatchCard:render()
	local match = self.props.match
	if not match then
		return nil
	end

	local matchPhase = MatchGroupUtil.computeMatchPhase(match)

	local displayMatchPage = Info.config.match2.matchPage and matchPhase ~= 'upcoming'
	local displayVods = matchPhase == 'finished'
	local displayStreams = matchPhase == 'ongoing'
	-- Show streams also for the last period before going live
	if matchPhase == 'upcoming' and
		os.difftime(match.timestamp, DateExt.getCurrentTimestamp()) < SHOW_STREAMS_WHEN_LESS_THAN_TO_LIVE then

		displayStreams = true
	end

	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	local highlight = highlightCondition(match, {onlyHighlightOnValue = self.props.onlyHighlightOnValue})

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

	local tournamentLink = TournamentTitle{
		tournament = Tournament.partialTournamentFromMatch(match),
		displayGameIcon = self.props.displayGameIcons,
		stageName = match.section,
	}

	local matchPageButton = MatchPageButton{
		matchId = match.matchId,
		hasMatchPage = Logic.isNotEmpty(match.bracketData.matchPage),
	}

	return HtmlWidgets.Div{
		classes = {'match-info', highlight and HIGHLIGHT_CLASS or nil},
		children = WidgetUtil.collect(
			MatchCountdown{match = match},
			MatchHeader{match = match},
			not self.props.hideTournament and HtmlWidgets.Div{
				classes = {'match-info-tournament'},
				children = {tournamentLink},
			} or nil,
			HtmlWidgets.Div{
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
		)
	}
end

return MatchCard

---
-- @Liquipedia
-- page=Module:Widget/Match/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local StreamLinks = Lua.import('Module:Links/Stream')
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

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'

---@class MatchCard: Widget
---@operator call(table): MatchCard
local MatchCard = Class.new(Widget)
MatchCard.defaultProps = {
	hideTournament = false, -- Hide the tournament and stage
	displayGameIcons = false, -- Display the game icon in the tournament title
	onlyHighlightOnValue = nil, -- Only highlight if the publishertier has this value
}

---@return Widget?
function MatchCard:render()
	---@type MatchGroupUtilMatch
	local match = self.props.match
	if not match then
		return nil
	end

	local matchPhase = MatchGroupUtil.computeMatchPhase(match)

	local displayVods = matchPhase == 'finished'
	local displayStreams = matchPhase == 'ongoing'
	if matchPhase == 'upcoming' then
		--- TODO MAKE PROPER: Check if less than 2 hour until start
		displayStreams = true
	end

	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	-- TODO: We need to matchRecord, not the parsedMatch here...
	local highlight = highlightCondition(match, {onlyHighlightOnValue = self.props.onlyHighlightOnValue})

	---@param vod string?
	---@param index integer?
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
			children = ImageIcon{imageLight = VodLink.getIcon(index)},
		}
	end

	-- TODO: Make work, and add stage
	local tournamentLink = TournamentTitle{
		tournament = {
			pageName = match.parent,
			displayName = Logic.emptyOr(
				match.tickername,
				match.tournament,
				match.parent:gsub('_', ' ')
			),
			tickerName = match.tickername,
			icon = match.icon,
			iconDark = match.icondark,
			series = match.series,
			game = match.game,
		},
		displayGameIcon = self.props.displayGameIcons
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
			-- TODO Update structure and classes
			not self.props.hideTournament and HtmlWidgets.Div{
				classes = {'match-details'},
				children = {
					HtmlWidgets.Div{
						classes = {'match-links'},
						children = {
							HtmlWidgets.Div{
								classes = {'match-tournament'},
								children = tournamentLink,
							}
						},
					},
				},
			} or nil,
			HtmlWidgets.Div{
				classes = {'match-links'}, -- TODO Update Class
				children = WidgetUtil.collect(
					matchPageButton,
					displayStreams and StreamLinks.buildDisplays(StreamLinks.filterStreams(match.stream)) or nil,
					displayVods and makeVodButton(match.vod) or nil -- TODO Make longer text if no matchPageButton
				)
			},
		)
	}
end

return MatchCard

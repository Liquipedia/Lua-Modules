---
-- @Liquipedia
-- page=Module:Widget/Match/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local HighlightConditions = Lua.import('Module:HighlightConditions')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchHeader = Lua.import('Module:Widget/Match/Header')
local MatchHeaderFfa = Lua.import('Module:Widget/Match/Header/Ffa')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local TournamentBar = Lua.import('Module:Widget/Match/TournamentBar')
local ButtonBar = Lua.import('Module:Widget/Match/ButtonBar')
local StreamsContainer = Lua.import('Module:Widget/Match/StreamsContainer')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local StreamLinks = Lua.import('Module:Links/Stream')
local DateExt = Lua.import('Module:Date/Ext')
local String = Lua.import('Module:StringUtils')
local Link = Lua.import('Module:Widget/Basic/Link')

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'

---@class MatchCardProps
---@field match MatchGroupUtilMatch
---@field gameData MatchTickerGameData?
---@field onlyHighlightOnValue string?
---@field hideTournament boolean?
---@field displayGameIcons boolean?
---@field variant 'vertical'?

---@class MatchCard: Widget
---@operator call(MatchCardProps): MatchCard
---@field props MatchCardProps
local MatchCard = Class.new(Widget)
MatchCard.defaultProps = {
	hideTournament = false, -- Hide the tournament and stage
	displayGameIcons = false, -- Display the game icon in the tournament title
	onlyHighlightOnValue = nil, -- Only highlight if the publishertier has this value
	variant = nil,
}

---@return Widget?
function MatchCard:render()
	local match = self.props.match
	local gameData = self.props.gameData
	if not match then
		return nil
	end

	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	local highlight = highlightCondition(match, {onlyHighlightOnValue = self.props.onlyHighlightOnValue})

	if self.props.variant == 'vertical' then
		return self:_renderVertical(match, gameData, highlight)
	else
		return self:_renderHorizontal(match, gameData, highlight)
	end
end

---@param match MatchGroupUtilMatch
---@param gameData MatchTickerGameData?
---@param highlight boolean
---@return Widget
function MatchCard:_renderHorizontal(match, gameData, highlight)
	local tournamentLink = TournamentBar{
		match = match,
		gameData = gameData,
		displayGameIcon = self.props.displayGameIcons,
	}

	return HtmlWidgets.Div{
		classes = {'match-info'},
		children = WidgetUtil.collect(
			MatchCountdown{match = match},
			MatchHeader{match = match},
			not self.props.hideTournament and HtmlWidgets.Div{
				classes = {'match-info-tournament', highlight and HIGHLIGHT_CLASS or nil},
				children = {tournamentLink},
			} or nil,
			MatchHeaderFfa{match = match},
			ButtonBar{match = match}
		)
	}
end

---@param match MatchGroupUtilMatch
---@param gameData MatchTickerGameData?
---@param highlight boolean
---@return Widget
function MatchCard:_renderVertical(match, gameData, highlight)
	local isFfa = #match.opponents > 2

	return HtmlWidgets.Div{
		classes = {'match-info', 'match-info--vertical'},
		children = WidgetUtil.collect(
			self:_renderVerticalTopRow(match),
			self:_renderStageName(match),
			not isFfa and MatchHeader{
				match = match,
				variant = 'vertical'
			} or nil,
			isFfa and self:_renderFfaInfo(match, gameData) or nil,
			not self.props.hideTournament and HtmlWidgets.Div{
				classes = {'match-info-tournament', highlight and HIGHLIGHT_CLASS or nil},
				children = {
					TournamentBar{
						match = match,
						gameData = gameData,
						displayGameIcon = self.props.displayGameIcons,
					}
				},
			} or nil
		)
	}
end

---@param match MatchGroupUtilMatch
---@return Widget
function MatchCard:_renderVerticalTopRow(match)
	return HtmlWidgets.Div{
		classes = {'match-info-top-row'},
		children = WidgetUtil.collect(
			MatchCountdown{match = match, format = 'compact'},
			self:_renderStreamButtons(match)
		)
	}
end

---@param match MatchGroupUtilMatch
---@return Widget?
function MatchCard:_renderStreamButtons(match)
	local phase = MatchGroupUtil.computeMatchPhase(match)
	local displayStreams = phase == 'ongoing'

	if phase == 'upcoming' and match.timestamp then
		local SHOW_STREAMS_THRESHOLD = 2 * 60 * 60
		if os.difftime(match.timestamp, DateExt.getCurrentTimestamp()) < SHOW_STREAMS_THRESHOLD then
			displayStreams = true
		end
	end

	if not displayStreams then
		return nil
	end

	local filteredStreams = StreamLinks.filterStreams(match.stream)

	return StreamsContainer{
		streams = filteredStreams,
		matchIsLive = phase == 'ongoing',
	}
end

---@param match MatchGroupUtilMatch
---@return Widget?
function MatchCard:_renderStageName(match)
	local stageName
	if match.bracketData and match.bracketData.inheritedHeader then
		stageName = DisplayHelper.expandHeader(match.bracketData.inheritedHeader)[1]
	end

	if not stageName then
		return nil
	end

	return HtmlWidgets.Span{
		classes = {'match-info-stage'},
		children = stageName
	}
end

---@param match MatchGroupUtilMatch
---@param gameData MatchTickerGameData?
---@return Widget
function MatchCard:_renderFfaInfo(match, gameData)
	if not gameData or not gameData.gameIds then
		return HtmlWidgets.Span{
			classes = {'match-info-ffa-info'},
			children = 'FFA Match'
		}
	end

	local mapIsSet = gameData and not String.isEmpty(gameData.map)

	return HtmlWidgets.Span{
		classes = {'match-info-ffa-info'},
		children = WidgetUtil.collect(
			'Game #',
			Array.interleave(gameData.gameIds, '-'),
			mapIsSet and {
				' on ',
				Link{
					link = gameData.map,
					children = gameData.mapDisplayName
				}
			} or nil
		)
	}
end

return MatchCard

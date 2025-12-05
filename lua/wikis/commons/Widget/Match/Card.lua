---
-- @Liquipedia
-- page=Module:Widget/Match/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Logic = Lua.import('Module:Logic')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchHeader = Lua.import('Module:Widget/Match/Header')
local MatchHeaderFfa = Lua.import('Module:Widget/Match/Header/Ffa')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local TournamentBar = Lua.import('Module:Widget/Match/TournamentBar')
local ButtonBar = Lua.import('Module:Widget/Match/ButtonBar')

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'

---@class MatchCardProps
---@field match MatchGroupUtilMatch
---@field gameData MatchTickerGameData?
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
	local gameData = self.props.gameData
	if not match then
		return nil
	end

	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	local highlight = highlightCondition(match, {onlyHighlightOnValue = self.props.onlyHighlightOnValue})

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

	local tournamentLink = TournamentBar{
		match = match,
		gameData = gameData,
		displayIcon = false,
	}

	return HtmlWidgets.Div{
		classes = {'match-info', 'match-info--vertical'},
		children = WidgetUtil.collect(
			self:_renderVerticalTopRow(match),
			self.props.hideTournament
				and self:_renderStageName(match, 1)
				or HtmlWidgets.Div{
					classes = {'match-info-tournament'},
					children = WidgetUtil.collect(
						tournamentLink,
						Logic.isNotEmpty(match.bracketData.inheritedHeader) and '-' or nil,
						self:_renderStageName(match, 3)
					),
				},
			not isFfa and MatchHeader{
				match = match,
				variant = 'vertical'
			} or nil,
			isFfa and self:_renderFfaInfo(match, gameData) or nil
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
			HtmlWidgets.Div{
				classes = {'match-info-stream-buttons'},
				children = self:_renderStreamButtons(match)
			}
		)
	}
end

---@param match MatchGroupUtilMatch
---@return Widget?
function MatchCard:_renderStreamButtons(match)
	if not MatchUtil.shouldShowStreams(match) then
		return nil
	end

	local filteredStreams = StreamLinks.filterStreams(match.stream)
	local phase = MatchGroupUtil.computeMatchPhase(match)

	return StreamsContainer{
		streams = filteredStreams,
		matchIsLive = phase == 'ongoing',
		maxStreams = MAX_VERTICAL_CARD_STREAMS,
		buttonSize = 'xs',
	}
end

---@param match MatchGroupUtilMatch
---@param variantIndex number? 1 for full name (default), 2 for medium, 3 for short
---@return Widget?
function MatchCard:_renderStageName(match, variantIndex)
	variantIndex = variantIndex or 1
	local stageName
	if match.bracketData and match.bracketData.inheritedHeader then
		stageName = DisplayHelper.expandHeader(match.bracketData.inheritedHeader)[variantIndex]
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

	local mapIsSet = not String.isEmpty(gameData.map)

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

---
-- @Liquipedia
-- page=Module:Widget/Match/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

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

	local tournamentLink = TournamentBar{
		match = match,
		gameData = gameData,
		displayGameIcon = self.props.displayGameIcons,
	}

	local classes = {'match-info'}
	if self.props.variant == 'vertical' then
		table.insert(classes, 'match-info--vertical')
	end

	return HtmlWidgets.Div{
		classes = classes,
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

return MatchCard

---
-- @Liquipedia
-- page=Module:Widget/Match/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Tournament = Lua.import('Module:Tournament')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchHeader = Lua.import('Module:Widget/Match/Header')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local TournamentTitle = Lua.import('Module:Widget/Tournament/Title')
local ButtonBar = Lua.import('Module:Widget/Match/ButtonBar')

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'

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

	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	local highlight = highlightCondition(match, {onlyHighlightOnValue = self.props.onlyHighlightOnValue})

	local tournamentLink = TournamentTitle{
		tournament = Tournament.partialTournamentFromMatch(match),
		displayGameIcon = self.props.displayGameIcons,
		stageName = match.section,
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
			ButtonBar{match = match}
		)
	}
end

return MatchCard

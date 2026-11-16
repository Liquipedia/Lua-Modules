---
-- @Liquipedia
-- page=Module:Widget/Match/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local HighlightConditions = Lua.import('Module:HighlightConditions')

local WidgetUtil = Lua.import('Module:Widget/Util')
local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local MatchHeader = Lua.import('Module:Widget/Match/Header')
local MatchHeaderFfa = Lua.import('Module:Widget/Match/Header/Ffa')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local TournamentBar = Lua.import('Module:Widget/Match/TournamentBar')
local ButtonBar = Lua.import('Module:Widget/Match/ButtonBar')
local MatchTickerCard = Lua.import('Module:Widget/Match/Ticker/Card')

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'

---@class MatchCardProps
---@field match MatchGroupUtilMatch
---@field gameData MatchTickerGameData?
---@field onlyHighlightOnValue string?
---@field hideTournament boolean?
---@field displayGameIcons boolean?
---@field variant 'horizontal' | 'vertical'

local defaultProps = {
	hideTournament = false, -- Hide the tournament and stage
	displayGameIcons = false, -- Display the game icon in the tournament title
	onlyHighlightOnValue = nil, -- Only highlight if the publishertier has this value
	variant = 'horizontal',
}

---@param props MatchCardProps
---@return VNode?
local function MatchCard(props)
	local match = props.match
	local gameData = props.gameData
	if not match then
		return nil
	end

	if props.variant == 'vertical' then
		return MatchTickerCard{
			match = match,
			gameData = gameData,
			onlyHighlightOnValue = props.onlyHighlightOnValue,
			hideTournament = props.hideTournament,
			displayGameIcons = props.displayGameIcons,
		}
	end

	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	local highlight = highlightCondition(match, {onlyHighlightOnValue = props.onlyHighlightOnValue})

	local tournamentLink = TournamentBar{
		match = match,
		gameData = gameData,
		displayGameIcon = props.displayGameIcons,
	}

	return Html.Div{
		classes = {'match-info'},
		children = WidgetUtil.collect(
			MatchCountdown{match = match},
			MatchHeader{match = match},
			not props.hideTournament and Html.Div{
				classes = {'match-info-tournament', highlight and HIGHLIGHT_CLASS or nil},
				children = {tournamentLink},
			} or nil,
			MatchHeaderFfa{match = match --[[@as FFAMatchGroupUtilMatch]]},
			ButtonBar{match = match}
		)
	}
end

return Component.component(MatchCard, defaultProps)

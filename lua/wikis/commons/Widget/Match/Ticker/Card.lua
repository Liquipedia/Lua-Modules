---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local HighlightConditions = Lua.import('Module:HighlightConditions')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local MatchTickerCardOpponents = Lua.import('Module:Widget/Match/Ticker/Opponents')
local TournamentBar = Lua.import('Module:Widget/Match/TournamentBar')
local MatchButtonBar = Lua.import('Module:Widget/Match/ButtonBar')
local WidgetUtil = Lua.import('Module:Widget/Util')

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'

---@class MatchTickerCardProps
---@field match MatchGroupUtilMatch
---@field gameData MatchTickerGameData?
---@field onlyHighlightOnValue string?
---@field displayGameIcons boolean?
---@field hideTournament boolean?

local MatchTickerCard = {}

---@param props MatchTickerCardProps
---@return VNode
function MatchTickerCard.render(props)
	local match = props.match

	return Html.Div{
		classes = {'match-ticker-card'},
		children = WidgetUtil.collect(
			MatchTickerCard.buildHeader(match),
			MatchTickerCardOpponents{match = match},
			MatchTickerCard.buildTournamentInfoBar(props),
			MatchButtonBar{match = match, showVods = true, buttonSize = 'xs'}
		)
	}
end

---@param match MatchGroupUtilMatch
---@return VNode
function MatchTickerCard.buildHeader(match)
	return Html.Div{
		classes = {'match-ticker-card__header'},
		children = {
			MatchCountdown{match = match, format = 'compact'},
			(match.bestof or 0) > 0 and Html.Div{
				children = {'Bo', match.bestof}
			} or nil
		}
	}
end

---@param props MatchTickerCardProps
---@return VNode?
function MatchTickerCard.buildTournamentInfoBar(props)
	local match = props.match
	if props.hideTournament then
		if #match.opponents <= 2 then
			return
		end
		return Html.Div{
			classes = {'match-info-tournament'},
			children = TournamentBar{
				match = match,
				gameData = props.gameData,
				displayIcon = false,
				displayTournamentName = false,
			},
		}
	end
	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	local highlight = highlightCondition(match, {onlyHighlightOnValue = props.onlyHighlightOnValue})
	return Html.Div{
		classes = {
			'match-info-tournament',
			highlight and HIGHLIGHT_CLASS or nil
		},
		children = TournamentBar{
			match = match,
			gameData = props.gameData,
			displayGameIcon = props.displayGameIcons,
		},
	}
end

return Component.component(MatchTickerCard.render)

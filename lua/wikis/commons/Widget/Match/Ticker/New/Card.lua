---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/New/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local TournamentBar = Lua.import('Module:Widget/Match/TournamentBar')
local MatchButtonBar = Lua.import('Module:Widget/Match/ButtonBar')

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'
local PARTY_OPPONENTS_DIVIDER = Html.Hr{classes = {'match-ticker-card__divider'}}

---@class MatchTickerCardProps
---@field match MatchGroupUtilMatch
---@field onlyHighlightOnValue string?

local MatchTickerCard = {}

---@param props MatchTickerCardProps
function MatchTickerCard.render(props)
	local match = props.match

	return Html.Div{
		classes = {'match-ticker-card'},
		children = {
			MatchTickerCard.buildHeader(match),
			MatchTickerCard.buildMatchOpponentsDisplay(match),
			MatchTickerCard.buildTournamentInfoBar(match, props.onlyHighlightOnValue),
			MatchButtonBar{match = match, showVods = true, buttonSize = 'xs'}
		}
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

---@param match MatchGroupUtilMatch
---@return VNode
function MatchTickerCard.buildMatchOpponentsDisplay(match)
	local matchOpponents = match.opponents
	local opponentsDisplay = Array.map(match.opponents, FnUtil.curry(MatchTickerCard.buildMatchOpponentDisplay, match))
	local hasDivider = Array.any(matchOpponents, function (opponent)
		local opponentType = opponent.type
		return Opponent.typeIsParty(opponentType) and Opponent.partySize(opponentType) > 1
	end)
	return Html.Div{
		classes = {'match-ticker-card__opponents'},
		children = hasDivider and Array.interleave(opponentsDisplay, PARTY_OPPONENTS_DIVIDER) or opponentsDisplay
	}
end

---@param match MatchGroupUtilMatch
---@param opponent standardOpponent
---@param opponentIndex integer
---@return VNode
function MatchTickerCard.buildMatchOpponentDisplay(match, opponent, opponentIndex)
	return Html.Div{
		classes = {
			'match-ticker-card__opponent',
			match.winner == opponentIndex and 'winner' or nil,
		},
		children = {
			OpponentDisplay.BlockOpponent{
				opponent = opponent,
				teamStyle = 'dynamic',
			},
			Html.Div{children = OpponentDisplay.InlineScore(opponent)},
		}
	}
end

---@param match MatchGroupUtilMatch
---@param onlyHighlightOnValue string?
---@return VNode
function MatchTickerCard.buildTournamentInfoBar(match, onlyHighlightOnValue)
	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	local highlight = highlightCondition(match, {onlyHighlightOnValue = onlyHighlightOnValue})
	return Html.Div{
		classes = {
			'match-info-tournament',
			highlight and HIGHLIGHT_CLASS or nil
		},
		children = TournamentBar{match = match},
	}
end

return Component.component(MatchTickerCard.render)

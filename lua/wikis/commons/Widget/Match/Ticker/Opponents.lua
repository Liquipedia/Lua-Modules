---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/Opponents
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local FFAMatchTickerCardOpponents = Lua.import('Module:Widget/Match/Ticker/Opponents/Ffa')

local PARTY_OPPONENTS_DIVIDER = Html.Hr{classes = {'match-ticker-card__divider'}}

local MatchTickerCardOpponents = {}

---@param props {match: MatchGroupUtilMatch}
---@return VNode?
function MatchTickerCardOpponents.render(props)
	local match = props.match

	if #match.opponents > 2 then
		---@cast props {match: FFAMatchGroupUtilMatch}
		return FFAMatchTickerCardOpponents(props)
	end
	return MatchTickerCardOpponents.buildNormalMatchOpponentsDisplay(match)
end

---@param match MatchGroupUtilMatch
---@return VNode
function MatchTickerCardOpponents.buildNormalMatchOpponentsDisplay(match)
	local matchOpponents = match.opponents
	local opponentsDisplay = Array.map(
		match.opponents,
		FnUtil.curry(MatchTickerCardOpponents.buildNormalMatchOpponentDisplay, match)
	)
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
function MatchTickerCardOpponents.buildNormalMatchOpponentDisplay(match, opponent, opponentIndex)
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

return Component.component(MatchTickerCardOpponents.render)

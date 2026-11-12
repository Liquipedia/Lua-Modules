---
-- @Liquipedia
-- page=Module:Widget/Match/Ticker/New/Card
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local MatchCountdown = Lua.import('Module:Widget/Match/Countdown')
local TournamentBar = Lua.import('Module:Widget/Match/TournamentBar')
local MatchButtonBar = Lua.import('Module:Widget/Match/ButtonBar')

local HIGHLIGHT_CLASS = 'tournament-highlighted-bg'

---@class MatchTickerCardProps
---@field match MatchGroupUtilMatch
---@field onlyHighlightOnValue string?

local MatchTickerCard = {}

---@param props MatchTickerCardProps
function MatchTickerCard.render(props)
	local match = props.match
	local highlightCondition = HighlightConditions.match or HighlightConditions.tournament
	local highlight = highlightCondition(match, {onlyHighlightOnValue = props.onlyHighlightOnValue})
	return Html.Div{
		classes = {'match-ticker-card'},
		children = {
			Html.Div{
				classes = {'match-ticker-card__header'},
				children = {
					MatchCountdown{match = match, format = 'compact'},
					match.bestof and Html.Div{
						children = {'Bo', match.bestof}
					} or nil
				}
			},
			Html.Div{
				classes = {'match-ticker-card__opponents'},
				children = Array.map(match.opponents, function (opponent, opponentIndex)
					return Html.Div{
						classes = {'match-ticker-card__opponent'},
						children = {
							OpponentDisplay.BlockOpponent{
								opponent = opponent,
								teamStyle = 'dynamic',
							},
							Html.Div{children = OpponentDisplay.InlineScore(opponent)},
						}
					}
				end)
			},
			Html.Div{
				classes = {'match-info-tournament', highlight and HIGHLIGHT_CLASS or nil},
				children = TournamentBar{match = match},
			},
			MatchButtonBar{match = match, showVods = true}
		}
	}
end

return Component.component(MatchTickerCard.render)

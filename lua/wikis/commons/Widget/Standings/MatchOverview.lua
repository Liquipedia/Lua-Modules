---
-- @Liquipedia
-- page=Module:Widget/Standings/MatchOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Label = Lua.import('Module:Widget/Basic/Label')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local TiebreakerScope = Lua.import('Module:Standings/Tiebreaker/Scope')

local RESULT_TYPES = {w = 'win', d = 'draw', l = 'loss'}

---@param props {match: MatchGroupUtilMatch, showOpponent: integer}
---@return Renderable?
local function MatchOverviewWidget(props)
	local match = props.match
	local opponentIndexToShow = tonumber(props.showOpponent)
	if not match or not opponentIndexToShow or #match.opponents ~= 2 then
		return
	end

	local opponentToShow = match.opponents[opponentIndexToShow]
	if not opponentToShow then
		return
	end

	local leftOpponent = Array.find(match.opponents, function(op) return op ~= opponentToShow end)
	if not leftOpponent then
		return
	end

	local phase = match.phase
	local isFinished = phase == 'finished'
	-- The result is from the point of view of the row's opponent (left), the same as in the match record,
	-- so a match without a winner (e.g. a double loss) is a loss and not a win
	local resultType = isFinished and RESULT_TYPES[TiebreakerScope.matchResult(match, leftOpponent)] or 'default'
	local shownOpponentWon = isFinished and TiebreakerScope.matchResult(match, opponentToShow) == 'w'

	return Html.Div{
		classes = {'standings-match-overview'},
		children = WidgetUtil.collect(
			phase ~= 'upcoming' and Label{
				labelScheme = 'standings-result',
				labelType = 'result-' .. resultType,
				children = {
					Html.Span{
						css = resultType == 'win' and {['font-weight'] = 'bold'} or nil,
						children = OpponentDisplay.InlineScore(leftOpponent)
					},
					Html.Span{children = ':'},
					Html.Span{
						css = shownOpponentWon and {['font-weight'] = 'bold'} or nil,
						children = OpponentDisplay.InlineScore(opponentToShow)
					}
				}
			} or nil,
			OpponentDisplay.InlineOpponent{
				opponent = opponentToShow,
				overflow = 'ellipsis',
				teamStyle = 'icon',
			}
		),
	}
end

return Component.component(MatchOverviewWidget)

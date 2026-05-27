---
-- @Liquipedia
-- page=Module:Widget/Standings/MatchOverview
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local Component = Lua.import('Module:Widget/Component')
local HtmlWidgets = Lua.import('Module:Widget/Html')
local Label = Lua.import('Module:Widget/Basic/Label')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

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
	local resultType

	if match.phase ~= 'finished' then
		resultType = 'default'
	elseif match.winner == opponentIndexToShow then
		resultType = 'loss'
	elseif match.winner == 0 then
		resultType = 'draw'
	else
		resultType = 'win'
	end

	return HtmlWidgets.Div{
		classes = {'standings-match-overview'},
		children = WidgetUtil.collect(
			phase ~= 'upcoming' and Label{
				labelScheme = 'standings-result',
				labelType = 'result-' .. resultType,
				children = {
					HtmlWidgets.Span{
						css = resultType == 'win' and {['font-weight'] = 'bold'} or nil,
						children = OpponentDisplay.InlineScore(leftOpponent)
					},
					HtmlWidgets.Span{children = ':'},
					HtmlWidgets.Span{
						css = resultType == 'loss' and {['font-weight'] = 'bold'} or nil,
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

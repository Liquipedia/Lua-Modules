---
-- @Liquipedia
-- page=Module:Widget/Match/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Span = Html.Span
local Div = Html.Div

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

---@class MatchHeaderProps
---@field match MatchGroupUtilMatch
---@field teamStyle? teamStyle
---@field variant 'horizontal'|'vertical'

local MatchHeader = {}
MatchHeader.defaultProps = {
	teamStyle = 'short',
	variant = 'horizontal',
}

---@param props MatchHeaderProps
---@return VNode?
function MatchHeader.render(props)
	local match = props.match
	if not match then
		return nil
	end

	-- TODO: Make work better with 2+ opponents (FFA/BR)
	if #match.opponents > 2 then
		return
	end

	if props.variant == 'vertical' then
		return MatchHeader._renderVertical(match, props.teamStyle)
	end

	return MatchHeader._renderHorizontal(match, props.teamStyle)
end

---@param match MatchGroupUtilMatch
---@param teamStyle teamStyle?
---@return VNode
function MatchHeader._renderHorizontal(match, teamStyle)
	local hasBestof = match.bestof and match.bestof > 0
	local matchPhase = MatchGroupUtil.computeMatchPhase(match)

	local leftTeamWinner = (match.winner == 1 or match.winner == 0)
	local rightTeamWinner = (match.winner == 2 or match.winner == 0)
	local leftTeamScore = OpponentDisplay.InlineScore(match.opponents[1])
	local rightTeamScore = OpponentDisplay.InlineScore(match.opponents[2])

	-- TODO: Investigate if this is still needed
	local hasBracketResetMatch = Array.any(match.opponents, function (opponent) return opponent.placement2 ~= nil end)
	if hasBracketResetMatch then
		leftTeamScore = 'W'
		rightTeamScore = 'L'
		leftTeamWinner = match.opponents[1].placement2 == 1
		rightTeamWinner = match.opponents[2].placement2 == 1
		hasBestof = false
	end

	return Div{
		classes = {'match-info-header'},
		children = {
			Div{
				classes = WidgetUtil.collect(
					'match-info-header-opponent',
					'match-info-header-opponent-left',
					matchPhase == 'finished' and not leftTeamWinner and 'match-info-header-loser' or nil,
					leftTeamWinner and 'match-info-header-winner' or nil
				),
				children = {
					OpponentDisplay.BlockOpponent{
						opponent = match.opponents[1],
						teamStyle = teamStyle,
						overflow = 'ellipsis',
						flip = true,
					}
				}
			},
			Div{
				classes = {'match-info-header-scoreholder'},
				children = {
					Span{
						classes = {'match-info-header-scoreholder-icon'},
						children = leftTeamWinner and Icon{iconName = 'winner_left'} or nil,
					},
					Span{
						classes = {'match-info-header-scoreholder-scorewrapper'},
						children = WidgetUtil.collect(
							Span{
								classes = {'match-info-header-scoreholder-upper'},
								children = matchPhase == 'upcoming' and {'vs'} or {
									Span{
										classes = {
											'match-info-header-scoreholder-score',
											leftTeamWinner and 'match-info-header-winner' or nil
										},
										children = leftTeamScore,
									},
									Span{
										classes = {'match-info-header-scoreholder-divider'},
										children = ':'
									},
									Span{
										classes = {
											'match-info-header-scoreholder-score',
											rightTeamWinner and 'match-info-header-winner' or nil
										},
										children = rightTeamScore,
									}
								}
							},
							hasBestof and Span{
								classes = {'match-info-header-scoreholder-lower'},
								children = '(Bo' .. match.bestof ..')'
							} or nil
						)
					},
					Span{
						classes = {'match-info-header-scoreholder-icon'},
						children = rightTeamWinner and Icon{iconName = 'winner_right'} or nil,
					}
				}
			},
			Div{
				classes = WidgetUtil.collect(
					'match-info-header-opponent',
					matchPhase == 'finished' and not rightTeamWinner and 'match-info-header-loser' or nil,
					rightTeamWinner and 'match-info-header-winner' or nil
				),
				children = {
					OpponentDisplay.BlockOpponent{
						opponent = match.opponents[2],
						teamStyle = teamStyle,
						overflow = 'ellipsis',
					}
				}
			},
		}
	}
end

---@param match MatchGroupUtilMatch
---@param teamStyle teamStyle?
---@return VNode
function MatchHeader._renderVertical(match, teamStyle)
	local matchPhase = MatchGroupUtil.computeMatchPhase(match)

	return Div{
		classes = {'match-info-header', 'match-info-header-vertical'},
		children = WidgetUtil.collect(
			Array.map(match.opponents, function(opponent, idx)
				local isWinner = (match.winner == idx or match.winner == 0)
				local score = OpponentDisplay.InlineScore(opponent)

				return Div{
					classes = WidgetUtil.collect(
						'match-info-opponent-row',
						matchPhase == 'finished' and not isWinner and 'match-info-opponent-row-loser' or nil,
						isWinner and 'match-info-opponent-row-winner' or nil
					),
					children = {
						Div{
							classes = {'match-info-opponent-identity'},
							children = {
								OpponentDisplay.BlockOpponent{
									opponent = opponent,
									teamStyle = teamStyle,
									overflow = 'ellipsis',
								}
							}
						},
						Span{
							classes = WidgetUtil.collect(
								'match-info-opponent-score',
								isWinner and 'match-info-opponent-score-winner' or nil
							),
							children = matchPhase ~= 'upcoming' and score or nil
						}
					}
				}
			end)
		)
	}
end

return Component.component(MatchHeader.render, MatchHeader.defaultProps)

---
-- @Liquipedia
-- page=Module:Widget/Match/Header
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local MatchGroupUtil = Lua.import('Module:MatchGroup/Util')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Icon = Lua.import('Module:Widget/Image/Icon/Fontawesome')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibraries.OpponentDisplay

---@class MatchHeader: Widget
---@operator call(table): MatchHeader
local MatchHeader = Class.new(Widget)
MatchHeader.defaultProps = {
}

---@return Widget?
function MatchHeader:render()
	---@type MatchGroupUtilMatch
	local match = self.props.match
	if not match then
		return nil
	end

	local hasBestof = match.bestof and match.bestof > 0
	local matchPhase = MatchGroupUtil.computeMatchPhase(match)

	local leftTeamWinner = (match.winner == 1 or match.winner == 0)
	local rightTeamWinner = (match.winner == 2 or match.winner == 0)

	return HtmlWidgets.Div{
		classes = {'match-info-header'},
		children = {
			HtmlWidgets.Div{
				classes = WidgetUtil.collect(
					'match-info-header-opponent',
					'match-info-header-opponent-left',
					matchPhase == 'finished' and not leftTeamWinner and 'match-info-header-loser' or nil,
					leftTeamWinner and 'match-info-header-winner' or nil
				),
				children = {
					OpponentDisplay.InlineOpponent{
						opponent = match.opponents[1],
						teamStyle = 'short',
						flip = true,
					}
				}
			},
			HtmlWidgets.Div{
				classes = {'match-info-header-scoreholder'},
				children = {
					HtmlWidgets.Span{
						classes = {hasBestof and 'match-info-header-scoreholder-upper' or nil},
						children = WidgetUtil.collect(
							HtmlWidgets.Span{
								classes = {'match-info-header-scoreholder-icon'},
								children = leftTeamWinner and Icon{iconName = 'winner_left'} or nil,
							},
							matchPhase ~= 'upcoming' and HtmlWidgets.Span{
								classes = {
									'match-info-header-scoreholder-score',
									leftTeamWinner and 'match-info-header-winner' or nil
								},
								children = OpponentDisplay.InlineScore(match.opponents[1]),
							} or nil,
							matchPhase ~= 'upcoming' and ':' or 'vs',
							matchPhase ~= 'upcoming' and HtmlWidgets.Span{
								classes = {
									'match-info-header-scoreholder-score',
									rightTeamWinner and 'match-info-header-winner' or nil
								},
								children = OpponentDisplay.InlineScore(match.opponents[2]),
							} or nil,
							HtmlWidgets.Span{
								classes = {'match-info-header-scoreholder-icon'},
								children = rightTeamWinner and Icon{iconName = 'winner_right'} or nil,
							}
						)
					},
					hasBestof and HtmlWidgets.Span{
						classes = {'match-info-header-scoreholder-lower'},
						children = '(Bo' .. match.bestof ..')'
					} or nil
				}
			},
			HtmlWidgets.Div{
				classes = WidgetUtil.collect(
					'match-info-header-opponent',
					matchPhase == 'finished' and not rightTeamWinner and 'match-info-header-loser' or nil,
					rightTeamWinner and 'match-info-header-winner' or nil
				),
				children = {
					OpponentDisplay.InlineOpponent{
						opponent = match.opponents[2],
						teamStyle = 'short',
					}
				}
			},
		}
	}
end

return MatchHeader

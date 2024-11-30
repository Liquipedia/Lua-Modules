---
-- @Liquipedia
-- wiki=commons
-- page=Module:Widget/Match/Summary/Ffa/GamesSchedule
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local ContentItemContainer = Lua.import('Module:Widget/Match/Summary/Ffa/ContentItemContainer')
local CountdownIcon = Lua.import('Module:Widget/Match/Summary/Ffa/CountdownIcon')
local GameCountdown = Lua.import('Module:Widget/Match/Summary/Ffa/GameCountdown')

---@class MatchSummaryFfaGamesSchedule: Widget
---@operator call(table): MatchSummaryFfaGamesSchedule
local MatchSummaryFfaGamesSchedule = Class.new(Widget)

---@return Widget?
function MatchSummaryFfaGamesSchedule:render()
	if not self.props.games or #self.props.games == 0 then
		return nil
	end

	return ContentItemContainer{collapsed = true, collapsible = true, title = 'Schedule', children = {
		HtmlWidgets.Ul{
			classes = {'panel-content__game-schedule'},
			children = Array.map(self.props.games, function (game, idx)
				return HtmlWidgets.Li{
					children = {
						HtmlWidgets.Span{
							children = CountdownIcon{
								game = game,
								additionalClasses = {'panel-content__game-schedule__icon'}
							},
						},
						HtmlWidgets.Span{
							classes = {'panel-content__game-schedule__title'},
							children = 'Game ' .. idx .. ':',
						},
						HtmlWidgets.Div{
							classes = {'panel-content__game-schedule__container'},
							children = GameCountdown{game = game},
						},
					},
				}
			end)
		}
	}}
end

return MatchSummaryFfaGamesSchedule

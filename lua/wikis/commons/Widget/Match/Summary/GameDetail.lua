---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameDetail
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local Div = Html.Div
local GameWinLossIndicator = Lua.import('Module:Widget/Match/Summary/GameWinLossIndicator')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class GameDetailProps
---@field game MatchGroupUtilGame
---@field gameIndex integer
---@field overview Renderable?
---@field children Renderable|Renderable[]

---@param props GameDetailProps
---@return VNode?
local function GameDetail(props)
	local game = props.game

	local gameOverview = props.overview

	return Div{
		classes = {'brkts-popup-game-detail'},
		children = WidgetUtil.collect(
			Div{
				classes = {'brkts-popup-game-detail-header'},
				children = {
					GameWinLossIndicator{
						opponentIndex = 1,
						winner = game.winner,
					},
					Div{
						classes = {'brkts-popup-game-detail-header-summary'},
						children = WidgetUtil.collect(
							'Game ',
							props.gameIndex,
							gameOverview and {
								' - ',
								gameOverview
							} or nil
						),
					},
					GameWinLossIndicator{
						opponentIndex = 2,
						winner = game.winner,
					},
				}
			},
			props.children
		)
	}
end

return Component.component(GameDetail)

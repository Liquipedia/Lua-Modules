---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Component = Lua.import('Module:Widget/Component')
local Html = Lua.import('Module:Widget/Html')
local GameCenter = Lua.import('Module:Widget/Match/Summary/GameCenter')
local GameWinLossIndicator = Lua.import('Module:Widget/Match/Summary/GameWinLossIndicator')

---@class MatchSummaryGameRowComponentProps
---@field getGameOpponentViewCss? fun(props: MatchSummaryGameRowProps, opponentIndex: integer): HtmlStyleProps
---@field createGameOpponentView fun(props: MatchSummaryGameRowProps, opponentIndex: integer): Renderable|Renderable[]?
---@field createGameOverview fun(props: MatchSummaryGameRowProps): Renderable|Renderable[]

---@class MatchSummaryGameRowProps
---@field allowWrappingInOverview boolean?
---@field css table<string, string|number>?
---@field game MatchGroupUtilGame
---@field gameIndex integer

local MatchSummaryGameRow = {}

---@generic P: MatchSummaryGameRowProps
---@param implProps MatchSummaryGameRowComponentProps
---@param defaultProps P
---@return Component<P>
---@overload fun(implProps: MatchSummaryGameRowComponentProps): Component<MatchSummaryGameRowProps>
function MatchSummaryGameRow.createComponent(implProps, defaultProps)
	---@param componentProps MatchSummaryGameRowProps
	---@return VNode
	local function componentImpl(componentProps)
		---@param opponentIndex integer
		---@return table<string, string|number?>?
		local function getGameOpponentViewCss(opponentIndex)
			if not implProps.getGameOpponentViewCss then
				return
			end
			return implProps.getGameOpponentViewCss(componentProps, opponentIndex)
		end
		local createGameOpponentView = FnUtil.curry(implProps.createGameOpponentView, componentProps)

		return Html.Div{
			classes = {'brkts-popup-body-grid-row'},
			css = componentProps.css,
			children = {
				GameWinLossIndicator{
					opponentIndex = 1,
					winner = componentProps.game.winner,
				},
				Html.Div{
					classes = {'brkts-popup-body-grid-row-detail'},
					children = {
						GameCenter{
							css = getGameOpponentViewCss(1),
							children = createGameOpponentView(1)
						},
						GameCenter{
							css = componentProps.allowWrappingInOverview and {
								['white-space'] = 'wrap',
							} or nil,
							children = implProps.createGameOverview(componentProps)
						},
						GameCenter{
							css = getGameOpponentViewCss(2),
							children = createGameOpponentView(2)
						}
					},
				},
				GameWinLossIndicator{
					opponentIndex = 2,
					winner = componentProps.game.winner,
				},
				MatchSummaryGameRow._renderGameComment(componentProps.game)
			},
		}
	end

	return Component.component(componentImpl, defaultProps)
end

---@param props MatchSummaryGameRowProps
---@return Renderable?
function MatchSummaryGameRow.lengthDisplay(props)
	local game = props.game
	return Logic.emptyOr(game.length, 'Game ' .. props.gameIndex)
end

---@param props MatchSummaryGameRowProps
---@param config {noLink: boolean?}?
---@return string
function MatchSummaryGameRow.mapDisplay(props, config)
	local game = props.game
	return DisplayHelper.Map(game, config)
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return string
function MatchSummaryGameRow.scoreDisplay(game, opponentIndex)
	return DisplayHelper.MapScore(game.opponents[opponentIndex], game.status)
end

---@package
---@param game MatchGroupUtilGame
---@return VNode?
function MatchSummaryGameRow._renderGameComment(game)
	if Logic.isEmpty(game.comment) then
		return
	end
	return Html.Div{
		classes = {'brkts-popup-comment'},
		children = game.comment,
	}
end

return MatchSummaryGameRow

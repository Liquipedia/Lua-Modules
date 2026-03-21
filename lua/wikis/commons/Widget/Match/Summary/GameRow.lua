---
-- @Liquipedia
-- page=Module:Widget/Match/Summary/GameRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')

local Widget = Lua.import('Module:Widget')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local GameCenter = Lua.import('Module:Widget/Match/Summary/GameCenter')
local GameWinLossIndicator = Lua.import('Module:Widget/Match/Summary/GameWinLossIndicator')

---@class MatchSummaryGameRowProps
---@field css table<string, string|number>?
---@field game MatchGroupUtilGame
---@field gameIndex integer

---@class MatchSummaryGameRow: Widget
---@operator call(MatchSummaryGameRowProps): MatchSummaryGameRow
---@field props MatchSummaryGameRowProps
local MatchSummaryGameRow = Class.new(Widget)

---@return Widget?
function MatchSummaryGameRow:render()
	local props = self.props
	return HtmlWidgets.Div{
		classes = {'brkts-popup-body-grid-row'},
		css = props.css,
		children = {
			GameWinLossIndicator{
				opponentIndex = 1,
				winner = props.game.winner,
			},
			HtmlWidgets.Div{
				classes = {'brkts-popup-body-grid-row-detail'},
				children = self:createGameDetail(),
			},
			GameWinLossIndicator{
				opponentIndex = 2,
				winner = props.game.winner,
			},
			self:_renderGameComment()
		},
	}
end

---@protected
---@return Renderable|Renderable[]
function MatchSummaryGameRow:createGameDetail()
	error('MatchSummaryGameRow:createGameDetail() cannot be called directly and must be overridden.')
end

---@protected
---@return Widget
function MatchSummaryGameRow:lengthDisplay()
	local game = self.props.game
	return GameCenter{children = Logic.emptyOr(game.length, 'Game ' .. self.props.gameIndex)}
end

---@protected
---@param config {noLink: boolean?}?
---@return Widget
function MatchSummaryGameRow:mapDisplay(config)
	local game = self.props.game
	return GameCenter{children = DisplayHelper.Map(game, config)}
end

---@protected
---@param opponentIndex integer
---@return string
function MatchSummaryGameRow:scoreDisplay(opponentIndex)
	local game = self.props.game
	return DisplayHelper.MapScore(game.opponents[opponentIndex], game.status)
end

---@private
function MatchSummaryGameRow:_renderGameComment()
	local game = self.props.game
	if Logic.isEmpty(game.comment) then
		return
	end
	return HtmlWidgets.Div{
		classes = {'brkts-popup-comment'},
		children = game.comment,
	}
end

return MatchSummaryGameRow

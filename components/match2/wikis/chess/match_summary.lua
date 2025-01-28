---
-- @Liquipedia
-- wiki=chess
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Eco = Lua.import('Module:Chess/ECO')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Icon = Lua.import('Module:Icon')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local Table = Lua.import('Module:Table')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Br = HtmlWidgets.Br
local Div = HtmlWidgets.Div
local Span = HtmlWidgets.Span

local KING_ICON_SIZE = '150%'
local WHITE_KING = Icon.makeIcon{
	iconName = 'chesskingwhite',
	additionalClasses = {'show-when-light-mode'},
	size = KING_ICON_SIZE,
} .. Icon.makeIcon{
	iconName = 'chesskingblack',
	additionalClasses = {'show-when-dark-mode'},
	size = KING_ICON_SIZE,
}
local BLACK_KING = Icon.makeIcon{
	iconName = 'chesskingblack',
	additionalClasses = {'show-when-light-mode'},
	size = KING_ICON_SIZE,
} .. Icon.makeIcon{
	iconName = 'chesskingwhite',
	additionalClasses = {'show-when-dark-mode'},
	size = KING_ICON_SIZE,
}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
		:css('overflow', 'auto')
		:css('max-height', '50vh')
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary.createGame(date, game, gameIndex)
	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {padding = '4px'},
		children = WidgetUtil.collect(
			-- Player 1
			CustomMatchSummary._getSideIcon(1, game.extradata.white),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameTeamWrapper{flipped = false},

			-- Center
			MatchSummaryWidgets.GameCenter{
				css = {
					['text-align'] = 'center',
					['align-content'] = 'center',
					['min-height'] = '42px',
					['font-size'] = '85%',
					['line-height'] = '12px',
					['max-width'] = '200px'
				},
				children = MatchSummaryWidgets._getCenterContent(game, gameIndex),
			},

			-- Player 2
			MatchSummaryWidgets.GameTeamWrapper{flipped = true},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			CustomMatchSummary._getSideIcon(2, game.extradata.white),

			-- Comment
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget
function MatchSummaryWidgets._getCenterContent(game, gameIndex)
	local vod = Table.extract(game, 'vod')
	local linksFooter = MatchSummary.Footer()
	MatchSummary.addVodsToFooter({vod = vod, games = {}}, linksFooter)
	linksFooter:addLinks(game.extradata.links)

	return Div{
		children = {
			Span{
				children = {
					'Game ' .. gameIndex,
					game.length and (' - ' .. game.length .. ' moves') or '',
				},
			},
			Br(),
			Span{
				css = {['font-size'] = '85%'},
				children = {Eco.getName(game.extradata.eco, true)},
			},
			Span{
				classes = {'brkts-popup-spaced', 'vodlink'},
				css = {['padding-top'] = '1px'},
				children = Array.map(linksFooter.elements, tostring),
			},
		},
	}
end

---@param opponentIndex integer
---@param white integer?
---@return Widget
function CustomMatchSummary._getSideIcon(opponentIndex, white)
	local icon = white == opponentIndex and WHITE_KING or white and BLACK_KING or ''

	return Div{classes = {'brkts-popup-spaced'}, css = {['padding'] = '0px 4px'}, children = icon}
end

return CustomMatchSummary

---
-- @Liquipedia
-- wiki=chess
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local CustomMatchSummary = {}

local Array = require('Module:Array')
local Lua = require('Module:Lua')

local Eco = Lua.import('Module:Chess/ECO')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Icon = Lua.import('Module:Icon')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

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
	local sideIcon1 = CustomMatchSummary._getSideIcon(1, game.extradata.white) or ''
	local sideIcon2 = CustomMatchSummary._getSideIcon(2, game.extradata.white) or ''

	-- TODO: Create center content using widgets' helpers.
	local centerContent = mw.html.create('div')
		:tag('span')
			:wikitext(('Game ' .. gameIndex) .. (game.extradata.movecount and (' - ' .. game.extradata.movecount .. ' moves') or ''))
			:done()
		:tag('br')
			:done()
		:tag('span')
			:css('font-size', '85%')
			:wikitext(Eco.getName(game.extradata.eco, true))
			:done()

	-- Links.
	-- TODO: Cleanup, remove game VODs from match footer.
	local linksFooter = MatchSummary.Footer()
	MatchSummary.addVodsToFooter({vod = game.vod, games = {}}, linksFooter)
	linksFooter:addLinks(game.extradata.links)
	centerContent:tag('span')
		:addClass('brkts-popup-spaced vodlink')
		:css('padding-top', '1px')
		:wikitext(table.concat(Array.map(linksFooter.elements, tostring)))

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {padding = '4px'},
		children = WidgetUtil.collect(
			-- Player 1.
			HtmlWidgets.Div{classes = {'brkts-popup-spaced'}, css = {['padding'] = '0px 4px'}, children = sideIcon1},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameTeamWrapper{flipped = false},

			-- Center.
			MatchSummaryWidgets.GameCenter{
				css = {['text-align'] = 'center', ['align-content'] = 'center', ['min-height'] = '42px', ['font-size'] = '85%', 
						['line-height'] = '12px', ['max-width'] = '200px'},
				children = centerContent
			},

			-- Player 2.
			MatchSummaryWidgets.GameTeamWrapper{flipped = true},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			HtmlWidgets.Div{classes = {'brkts-popup-spaced'}, css = {['padding'] = '0px 4px'}, children = sideIcon2},

			-- Comment.
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param opponentIndex integer
---@param white integer?
function CustomMatchSummary._getSideIcon(opponentIndex, white)
--todo: make/use a widget
	if not white then return end
	return white == opponentIndex and WHITE_KING or BLACK_KING
end

return CustomMatchSummary

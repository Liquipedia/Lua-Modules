---
-- @Liquipedia
-- wiki=tetris
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px'})
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex)
	return mw.html.create('div'):wikitext(game.scores[opponentIndex])
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Html?
function CustomMatchSummary.createGame(date, game, gameIndex)
	local row = MatchSummary.Row()

	row:addClass('brkts-popup-body-game')
		:css('font-size', '84%')
		:css('padding', '4px')
		:css('min-height', '32px')

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
		:node(CustomMatchSummary._gameScore(game, 1))

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(game.map)

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})

	row:addElement(leftNode)
		:addElement(centerNode)
		:addElement(rightNode)

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		row:addElement(mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		)
	end

	return row:create()
end

return CustomMatchSummary

---
-- @Liquipedia
-- wiki=clashofclans
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px'})
end

function CustomMatchSummary.createHeader(match)
	local header = MatchSummary.Header()

	local opponentLeft = match.opponents[1]
	local opponentRight = match.opponents[2]

	-- for Bo1 overwritte opponents scores with game score for matchsummary header display
	if match.bestof == 1 and match.games and match.games[1] and
		not match.opponents[1].placement2 and not match.opponents[2].placement2 then

		opponentLeft = Table.merge(match.opponents[1], {score = (match.games[1].scores or {})[1] or 0})
		opponentRight = Table.merge(match.opponents[2], {score = (match.games[1].scores or {})[2] or 0})
	end


	header:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
		:leftScore(header:createScore(opponentLeft))
		:rightScore(header:createScore(opponentRight))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary._gameScore(game, opponentIndex)
	return mw.html.create('div')
		:css('width', '16px')
		:wikitext(DisplayHelper.MapScore(
			game.scores[opponentIndex],
			opponentIndex,
			game.resultType,
			game.walkover,
			game.winner
		))
end

function CustomMatchSummary._percentage(game, opponentIndex)
	local percentage = game.extradata.percentages[opponentIndex]

	if not percentage then return end

	return mw.html.create('div')
		:css('font-size', '80%')
		:css('width', '48px')
		:wikitext(Abbreviation.make('(' .. percentage .. '%)', 'Average Damage Percentage'))
end

function CustomMatchSummary._time(game, opponentIndex)
	local time = game.extradata.times[opponentIndex]

	if not time then return end

	return mw.html.create('div')
		:css('font-size', '80%')
		:css('width', '40px')
		:wikitext(Abbreviation.make('(' .. os.date('%M:%S', time) .. ')', 'Total Time'))
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Html?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if Table.isEmpty(game.scores) then
		return
	end
	local row = MatchSummary.Row()

	-- Add Header
	if Logic.isNotEmpty(game.header) then
		local mapHeader = mw.html.create('div')
			:wikitext(game.header)
			:css('font-weight','bold')
			:css('font-size','85%')
			:css('margin','auto')
		row:addElement(mapHeader)
		row:addElement(MatchSummaryWidgets.Break{})
	end

	local centerNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:wikitext('Game ' .. gameIndex)

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	local leftNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
		:node(CustomMatchSummary._gameScore(game, 1))
		:node(CustomMatchSummary._percentage(game, 1))
		:node(CustomMatchSummary._time(game, 1))

	local rightNode = mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:node(CustomMatchSummary._time(game, 2))
		:node(CustomMatchSummary._percentage(game, 2))
		:node(CustomMatchSummary._gameScore(game, 2))
		:node(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})

	row:addElement(leftNode)
		:addElement(centerNode)
		:addElement(rightNode)

	row:addClass('brkts-popup-body-game')
		:css('text-align', 'center')
		:css('overflow', 'hidden')

	-- Add Comment
	if Logic.isNotEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
			:wikitext(game.comment)
			:css('margin', 'auto')
		row:addElement(comment)
	end

	return row:create()
end

return CustomMatchSummary

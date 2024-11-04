---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '500px', teamStyle = 'bracket'})
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Html?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end

	local row = MatchSummary.Row()

	local function scoreDisplay(oppIdx)
		return DisplayHelper.MapScore(game.scores[oppIdx], oppIdx, game.resultType, game.walkover, game.winner)
	end

	local function makePartialScores(halves, firstSide)
		local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)
		return {
			{style = 'brkts-valorant-score-color-' .. firstSide, score = halves[firstSide]},
			{style = 'brkts-valorant-score-color-' .. oppositeSide, score = halves[oppositeSide]},
			{style = 'brkts-valorant-score-color-' .. firstSide, score = halves['ot' .. firstSide]},
			{style = 'brkts-valorant-score-color-' .. oppositeSide, score = halves['ot' .. oppositeSide]},
		}
	end

	local team1Agents = Array.map((game.opponents[1] or {}).players or {}, Operator.property('agent'))
	local team2Agents = Array.map((game.opponents[2] or {}).players or {}, Operator.property('agent'))

	local extradata = game.extradata or {}

	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
	row:addElement(MatchSummaryWidgets.Characters{characters = team1Agents, flipped = false})
	row:addElement(MatchSummaryWidgets.DetailedScore{
		score = scoreDisplay(1),
		flipped = false,
		partialScores = makePartialScores(
			extradata.t1halfs or {},
			extradata.t1firstside or ''
		)
	})

	local centerNode = mw.html.create('div')
	centerNode	:addClass('brkts-popup-spaced')
				:wikitext('[[' .. game.map .. ']]')
				:css('width', '68px')
				:css('text-align', 'center')

	if game.resultType == 'np' then
		centerNode:addClass('brkts-popup-spaced-map-skip')
	end

	row:addElement(centerNode)

	row:addElement(MatchSummaryWidgets.DetailedScore{
		score = scoreDisplay(2),
		flipped = true,
		partialScores = makePartialScores(
			extradata.t2halfs or {},
			CustomMatchSummary._getOppositeSide(extradata.t1firstside or '')
		)
	})
	row:addElement(MatchSummaryWidgets.Characters{characters = team2Agents, flipped = true})
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})

	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	row:css('font-size', '85%')
	row:addClass('brkts-popup-body-game')
	return row:create()
end

---@param side string
---@return string
function CustomMatchSummary._getOppositeSide(side)
	if side == 'atk' then
		return 'def'
	end
	return 'atk'
end

return CustomMatchSummary

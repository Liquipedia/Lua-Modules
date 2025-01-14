---
-- @Liquipedia
-- wiki=valorant
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Lua = require('Module:Lua')
local Operator = require('Module:Operator')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '500px', teamStyle = 'bracket'})
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end

	local function scoreDisplay(oppIdx)
		return DisplayHelper.MapScore(game.opponents[oppIdx], game.status)
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

	local extradata = game.extradata or {}
	local function makeTeamSection(opponentIndex)
		local flipped = opponentIndex == 2
		local firstSide = flipped and CustomMatchSummary._getOppositeSide(extradata.t1firstside) or extradata.t1firstside
		local characters = Array.map((game.opponents[opponentIndex] or {}).players or {}, Operator.property('agent'))
		return {
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			MatchSummaryWidgets.Characters{characters = characters, flipped = flipped, hideOnMobile = true},
			MatchSummaryWidgets.DetailedScore{
				score = scoreDisplay(opponentIndex),
				flipped = flipped,
				partialScores = makePartialScores(
					extradata['t' .. opponentIndex .. 'halfs'] or {},
					firstSide or ''
				)
			}
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '85%'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game)},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param side string?
---@return string
function CustomMatchSummary._getOppositeSide(side)
	if side == 'atk' then
		return 'def'
	end
	return 'atk'
end

return CustomMatchSummary

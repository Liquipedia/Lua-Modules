---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

---@class ValorantMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class ValorantMatchSummaryGameRowComponentImpl: MatchSummaryGameRowComponentImpl
local GameRowComponentImpl = {
	createGameOverview = MatchSummaryWidgets.GameRow.mapDisplay,
}

local ValorantMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentImpl)

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '500px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return VNode[]
function CustomMatchSummary.createBody(match)
	return {
		MatchSummaryWidgets.GamesContainer{
			children = Array.map(match.games, function (game, gameIndex)
				if Logic.isEmpty(game.map) then
					return
				end
				return ValorantMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game}))
	}
end

---@private
---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return table[]
function GameRowComponentImpl._makePartialScores(game, opponentIndex)
	local extradata = game.extradata or {}
	local firstSide = extradata.t1firstside or ''
	local oppositeSide = GameRowComponentImpl._getOppositeSide(firstSide)
	local halves = extradata['t' .. opponentIndex .. 'halfs'] or {}
	if opponentIndex == 2 then
		firstSide, oppositeSide = oppositeSide, firstSide
	end
	return {
		{style = 'brkts-valorant-score-color-' .. firstSide, score = halves[firstSide]},
		{style = 'brkts-valorant-score-color-' .. oppositeSide, score = halves[oppositeSide]},
		{style = 'brkts-valorant-score-color-' .. firstSide, score = halves['ot' .. firstSide]},
		{style = 'brkts-valorant-score-color-' .. oppositeSide, score = halves['ot' .. oppositeSide]},
	}
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode[]
function GameRowComponentImpl.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local flipped = opponentIndex == 2
	local characters = Array.map((game.opponents[opponentIndex] or {}).players or {}, Operator.property('agent'))
	return {
		MatchSummaryWidgets.Characters{characters = characters, flipped = flipped, hideOnMobile = true},
		MatchSummaryWidgets.DetailedScore{
			score = MatchSummaryWidgets.GameRow.scoreDisplay(game, opponentIndex),
			partialScores = GameRowComponentImpl._makePartialScores(game, opponentIndex)
		}
	}
end

---@param side string?
---@return string
function GameRowComponentImpl._getOppositeSide(side)
	if Logic.isEmpty(side) then
		return ''
	elseif side == 'atk' then
		return 'def'
	end
	return 'atk'
end

return CustomMatchSummary

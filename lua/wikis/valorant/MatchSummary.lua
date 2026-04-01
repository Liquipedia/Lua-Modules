---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ValorantMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class ValorantMatchSummaryGameRow: MatchSummaryGameRow
---@operator call(MatchSummaryGameRowProps): ValorantMatchSummaryGameRow
local ValorantMatchSummaryGameRow = Class.new(MatchSummaryWidgets.GameRow)

---@param args table
---@return Widget
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '500px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return Widget[]
function CustomMatchSummary.createBody(match)
	return WidgetUtil.collect(
		MatchSummaryWidgets.GamesContainer{
			gridLayout = 'standard',
			children = Array.map(match.games, function (game, gameIndex)
				if Logic.isEmpty(game.map) then
					return
				end
				return ValorantMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game}))
	)
end

---@return string
function ValorantMatchSummaryGameRow:createGameOverview()
	return self:mapDisplay()
end

---@private
---@param opponentIndex integer
---@return table[]
function ValorantMatchSummaryGameRow:_makePartialScores(opponentIndex)
	local game = self.props.game
	local extradata = game.extradata or {}
	local firstSide = extradata.t1firstside or ''
	local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)
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

---@param opponentIndex integer
---@return Widget[]
function ValorantMatchSummaryGameRow:createGameOpponentView(opponentIndex)
	local game = self.props.game
	local flipped = opponentIndex == 2
	local characters = Array.map((game.opponents[opponentIndex] or {}).players or {}, Operator.property('agent'))
	return {
		MatchSummaryWidgets.Characters{characters = characters, flipped = flipped, hideOnMobile = true},
		MatchSummaryWidgets.DetailedScore{
			score = self:scoreDisplay(opponentIndex),
			partialScores = self:_makePartialScores(opponentIndex)
		}
	}
end

---@param side string?
---@return string
function CustomMatchSummary._getOppositeSide(side)
	if Logic.isEmpty(side) then
		return ''
	elseif side == 'atk' then
		return 'def'
	end
	return 'atk'
end

return CustomMatchSummary

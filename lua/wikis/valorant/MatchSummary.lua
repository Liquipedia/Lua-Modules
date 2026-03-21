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

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
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
		MatchSummaryWidgets.GameContainer{
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

---@return Widget[]
function ValorantMatchSummaryGameRow:createGameDetail()
	local game = self.props.game

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

	---@param opponentIndex integer
	---@return Widget[]
	local function makeTeamSection(opponentIndex)
		local flipped = opponentIndex == 2
		local firstSide = flipped and CustomMatchSummary._getOppositeSide(extradata.t1firstside) or extradata.t1firstside
		local characters = Array.map((game.opponents[opponentIndex] or {}).players or {}, Operator.property('agent'))
		return {
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

	return {
		MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
		MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game)},
		MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true}
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

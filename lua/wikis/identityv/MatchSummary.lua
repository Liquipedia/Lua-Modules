---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local Operator = Lua.import('Module:Operator')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class IdentityVCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class IdentityVMatchSummaryGameRow: MatchSummaryGameRow
---@operator call(MatchSummaryGameRowProps): IdentityVMatchSummaryGameRow
local IdentityVMatchSummaryGameRow = Class.new(MatchSummaryWidgets.GameRow)
IdentityVMatchSummaryGameRow.defaultProps = {
	allowWrappingInOverview = true
}

---@param args table
---@return Widget
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '500px'})
end

---@param match MatchGroupUtilMatch
---@return Widget[]
function CustomMatchSummary.createBody(match)
	local characterBansData = Array.map(match.games, function(game)
		local extradata = game.extradata or {}
		return {
			extradata.t1bans,
			extradata.t2bans,
		}
	end)

	return WidgetUtil.collect(
		MatchSummaryWidgets.GamesContainer{
			children = Array.map(match.games, function (game, gameIndex)
				if not game.map and not CustomMatchSummary.hasScores(game) then
					return
				end
				return IdentityVMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game})),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---@param opponentIndex integer
---@return Widget[]
function IdentityVMatchSummaryGameRow:createGameOpponentView(opponentIndex)
	local game = self.props.game
	local extradata = game.extradata or {}
	local flipped = opponentIndex == 2

	local function getFirstSide()
		if opponentIndex == 1 then
			return extradata.t1firstside
		end
		return CustomMatchSummary._getOppositeSide(extradata.t1firstside)
	end

	local firstSide = getFirstSide()
	local secondSide = CustomMatchSummary._getOppositeSide(firstSide)
	local halfs = extradata['t' .. opponentIndex .. 'halfs'] or {}
	local scoreDetails = {
		{score = halfs[firstSide], style = 'brkts-identityv-score-color-' .. firstSide},
		{score = halfs[secondSide], style = 'brkts-identityv-score-color-' .. secondSide},
	}

	local characters = extradata['t' .. opponentIndex .. 'picks'] or {}
	return {
		MatchSummaryWidgets.Characters{characters = characters, flipped = flipped, hideOnMobile = true},
		MatchSummaryWidgets.DetailedScore{
			score = self:scoreDisplay(opponentIndex),
			flipped = flipped,
			partialScores = scoreDetails,
		}
	}
end

---@return Renderable?
function IdentityVMatchSummaryGameRow:createGameOverview()
	return self:mapDisplay()
end

---@param side string
---@return string
function CustomMatchSummary._getOppositeSide(side)
	if side == 'hunter' then
		return 'survivor'
	elseif side == 'survivor' then
		return 'hunter'
	end
	return ''
end

---@param game MatchGroupUtilGame
---@return boolean
function CustomMatchSummary.hasScores(game)
	local scores = Array.map(game.opponents, Operator.property('score'))
	return Array.any(scores, function(score) return score ~= 0 end)
end

return CustomMatchSummary

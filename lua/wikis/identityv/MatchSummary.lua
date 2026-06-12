---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local Operator = Lua.import('Module:Operator')

---@class IdentityVCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

local IdentityVMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(
	{
		createGameOpponentView = CustomMatchSummary.createGameOpponentView,
		createGameOverview = MatchSummaryWidgets.GameRow.mapDisplay
	},
	{
		allowWrappingInOverview = true
	}
)

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '500px'})
end

---@param match MatchGroupUtilMatch
---@return VNode[]
function CustomMatchSummary.createBody(match)
	local characterBansData = Array.map(match.games, function(game)
		local extradata = game.extradata or {}
		return {
			extradata.t1bans,
			extradata.t2bans,
		}
	end)

	return {
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
	}
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode[]
function CustomMatchSummary.createGameOpponentView(props, opponentIndex)
	local game = props.game
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
	local scoreDetails = {}

	if Logic.isNotEmpty(firstSide) then
		scoreDetails = {
			{score = halfs[firstSide], style = 'brkts-identityv-score-color-' .. firstSide},
			{score = halfs[secondSide], style = 'brkts-identityv-score-color-' .. secondSide},
		}
	end

	local characters = extradata['t' .. opponentIndex .. 'picks'] or {}
	return {
		MatchSummaryWidgets.Characters{characters = characters, flipped = flipped, hideOnMobile = true},
		MatchSummaryWidgets.DetailedScore{
			score = MatchSummaryWidgets.GameRow.scoreDisplay(game, opponentIndex),
			flipped = flipped,
			partialScores = scoreDetails,
		}
	}
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

---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Table = Lua.import('Module:Table')

local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')

local ROUND_ICONS = {
	atk = IconImage{
		imageLight = 'R6S Para Bellum atk logo.png',
		size = '14px',
	},
	def = IconImage{
		imageLight = 'R6S Para Bellum def logo.png',
		size = '14px',
	},
	otatk = IconImage{
		imageLight = 'R6S Para Bellum atk logo ot rounds.png',
		size = '11px',
	},
	otdef = IconImage{
		imageLight = 'R6S Para Bellum def logo ot rounds.png',
		size = '11px',
	},
}

---@class RainbowsixMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

local RainbowsixMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent{
	createGameOpponentView = CustomMatchSummary.createGameOpponentView,
	createGameOverview = MatchSummaryWidgets.GameRow.mapDisplay
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
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
			gridLayout = 'standard',
			children = Array.map(match.games, function (game, gameIndex)
				if Logic.isEmpty(game.map) then
					return
				end
				return RainbowsixMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game})),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	}
end

---@private
---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return table[]
function CustomMatchSummary._makePartialScores(game, opponentIndex)
	local extradata = game.extradata or {}
	local halves = extradata['t' .. opponentIndex .. 'halfs']

	---@type table
	local firstSides = Table.mapValues(
		extradata.t1firstside or {},
		function (side)
			if opponentIndex == 1 then
				return side
			end
			return CustomMatchSummary._getOppositeSide(side:lower())
		end
	)
	local firstSide = (firstSides.rt or '')
	local firstSideOt = (firstSides.ot or '')
	local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)
	local oppositeSideOt = CustomMatchSummary._getOppositeSide(firstSideOt)
	return {
		{score = halves[firstSide], icon = ROUND_ICONS[firstSide]},
		{score = halves[oppositeSide], icon = ROUND_ICONS[oppositeSide]},
		{score = halves['ot' .. firstSideOt], icon = ROUND_ICONS['ot' .. firstSideOt]},
		{score = halves['ot' .. oppositeSideOt], icon = ROUND_ICONS['ot' .. oppositeSideOt]},
	}
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode
function CustomMatchSummary.createGameOpponentView(props, opponentIndex)
	local game = props.game
	return MatchSummaryWidgets.DetailedScore{
		score = MatchSummaryWidgets.GameRow.scoreDisplay(game, opponentIndex),
		partialScores = CustomMatchSummary._makePartialScores(game, opponentIndex)
	}
end

---@param side string
---@return string
function CustomMatchSummary._getOppositeSide(side)
	if side == 'atk' then
		return 'def'
	elseif side == 'def' then
		return 'atk'
	end
	return ''
end

return CustomMatchSummary

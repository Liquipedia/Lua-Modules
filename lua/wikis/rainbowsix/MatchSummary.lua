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
local Table = Lua.import('Module:Table')

local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local IconImage = Lua.import('Module:Widget/Image/Icon/Image')
local WidgetUtil = Lua.import('Module:Widget/Util')

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

---@class RainbowsixMatchSummaryGameRow: MatchSummaryGameRow
---@operator call(MatchSummaryGameRowProps): RainbowsixMatchSummaryGameRow
local RainbowsixMatchSummaryGameRow = Class.new(MatchSummaryWidgets.GameRow)

---@param args table
---@return Widget
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
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
	)
end

---@private
---@param opponentIndex integer
---@return table[]
function RainbowsixMatchSummaryGameRow:_makePartialScores(opponentIndex)
	local game = self.props.game
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

---@param opponentIndex integer
---@return Widget
function RainbowsixMatchSummaryGameRow:createGameOpponentView(opponentIndex)
	return MatchSummaryWidgets.DetailedScore{
		score = self:scoreDisplay(opponentIndex),
		flipped = opponentIndex,
		partialScores = self:_makePartialScores(opponentIndex)
	}
end

---@return string
function RainbowsixMatchSummaryGameRow:createGameOverview()
	return self:mapDisplay()
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

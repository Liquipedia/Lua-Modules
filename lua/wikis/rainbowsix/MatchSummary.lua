---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local FnUtil = require('Module:FnUtil')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ROUND_ICONS = {
	atk = '[[File:R6S Para Bellum atk logo.png|14px|link=]]',
	def = '[[File:R6S Para Bellum def logo.png|14px|link=]]',
	otatk = '[[File:R6S Para Bellum atk logo ot rounds.png|11px|link=]]',
	otdef = '[[File:R6S Para Bellum def logo ot rounds.png|11px|link=]]',
}

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '360px'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	local characterBansData = Array.map(match.games, function(game)
		local extradata = game.extradata or {}
		return {
			extradata.t1bans,
			extradata.t2bans,
		}
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, FnUtil.curry(CustomMatchSummary.createGame, match.date)),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game})),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)}
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end
	local extradata = game.extradata or {}

	local function scoreDisplay(oppIdx)
		return DisplayHelper.MapScore(game.opponents[oppIdx], game.status)
	end

	local function makePartialScores(halves, firstSide, firstSideOt)
		local oppositeSide = CustomMatchSummary._getOppositeSide(firstSide)
		local oppositeSideOt = CustomMatchSummary._getOppositeSide(firstSideOt)
		return {
			{score = halves[firstSide], icon = ROUND_ICONS[firstSide]},
			{score = halves[oppositeSide], icon = ROUND_ICONS[oppositeSide]},
			{score = halves['ot' .. firstSideOt], icon = ROUND_ICONS['ot' .. firstSideOt]},
			{score = halves['ot' .. oppositeSideOt], icon = ROUND_ICONS['ot' .. oppositeSideOt]},
		}
	end

	local firstSides = extradata.t1firstside or {}
	local firstSide = (firstSides.rt or ''):lower()
	local firstSideOt = (firstSides.ot or ''):lower()

	-- Winner/Loser backgrounds
	local gameStatusBackground = 'brkts-popup-body-gradient-default'
	if game.winner == 1 then
		gameStatusBackground = 'brkts-popup-body-gradient-left'
	elseif game.winner == 2 then
		gameStatusBackground = 'brkts-popup-body-gradient-right'
	elseif game.winner == 0 then
		gameStatusBackground = 'brkts-popup-body-gradient-draw'
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game', gameStatusBackground},
		css = {['font-size'] = '85%'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.DetailedScore{
				score = scoreDisplay(1),
				flipped = false,
		partialScores = makePartialScores(
					extradata.t1halfs or {},
					firstSide,
					firstSideOt
				)
			},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game), css = {['flex-grow'] = '1'}},
			MatchSummaryWidgets.DetailedScore{
				score = scoreDisplay(2),
				flipped = true,
		partialScores = makePartialScores(
					extradata.t2halfs or {},
					CustomMatchSummary._getOppositeSide(firstSide),
					CustomMatchSummary._getOppositeSide(firstSideOt)
				)
			},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
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

---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local Operator = Lua.import('Module:Operator')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomMatchSummary = {}

---@param args table
---@return Html
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
		Array.map(match.games, CustomMatchSummary.createGame),
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.MapVeto(MatchSummary.preProcessMapVeto(match.extradata.mapveto, {game = match.game})),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	)
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(game, gameIndex)
	if not game.map and not CustomMatchSummary.hasScores(game) then
		return
	end

	local scoreDisplay = function(oppIdx)
		return DisplayHelper.MapScore(game.opponents[oppIdx], game.status)
	end

	local extradata = game.extradata or {}
	local getScoreDetails = function(oppIdx)
		local firstSide = oppIdx == 1 and extradata.t1firstside or CustomMatchSummary._getOppositeSide(extradata.t1firstside)
		local secondSide = CustomMatchSummary._getOppositeSide(firstSide)
		return {
			{score = (extradata.t1halfs or {})[firstSide], style = 'brkts-identityv-score-color-' .. firstSide},
			{score = (extradata.t2halfs or {})[secondSide], style = 'brkts-identityv-score-color-' .. secondSide},
		}
	end

	local function makeTeamSection(opponentIndex)
		local flipped = opponentIndex == 2
		local characters = extradata['t' .. opponentIndex .. 'picks'] or {}
		return {
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			MatchSummaryWidgets.Characters{characters = characters, flipped = flipped, hideOnMobile = true},
			MatchSummaryWidgets.DetailedScore{
				score = scoreDisplay(opponentIndex),
				flipped = flipped,
				partialScores = getScoreDetails(opponentIndex),
			}
		}
	end

	local mapInfo = {
		mapDisplayName = game.map,
		map = game.map,
	}

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(mapInfo), css = {['flex-grow'] = '1'}},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
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

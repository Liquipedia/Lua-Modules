---
-- @Liquipedia
-- wiki=overwatch
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local MapModes = require('Module:MapModes')
local String = require('Module:StringUtils')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Html?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end

	local function makeTeamSection(opponentIndex)
		return {
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			CustomMatchSummary._gameScore(game, opponentIndex)
		}
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(1)},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game)},
			MatchSummaryWidgets.GameTeamWrapper{children = makeTeamSection(2), flipped = true},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._gameScore(game, opponentIndex)
	local score = game.scores[opponentIndex] --[[@as number|string?]]
	if score and game.mode == 'Push' then
		score = score .. 'm'
	end
	local scoreDisplay = DisplayHelper.MapScore(score, opponentIndex, game.resultType, game.walkover, game.winner)
	return mw.html.create('div'):wikitext(scoreDisplay)
end

---@param game MatchGroupUtilGame
---@return string
function CustomMatchSummary._getMapDisplay(game)
	local mapDisplay = DisplayHelper.Map(game)
	if String.isNotEmpty(game.mode) then
		mapDisplay = MapModes.get{mode = game.mode} .. mapDisplay
	end
	return mapDisplay
end

return CustomMatchSummary

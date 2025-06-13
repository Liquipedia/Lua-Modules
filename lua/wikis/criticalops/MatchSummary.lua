---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px'})
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end

	local function score(oppIdx)
		return DisplayHelper.MapScore(game.opponents[oppIdx], game.status)
	end

	-- Teams scores
	local extradata = game.extradata or {}
	local t1sides = extradata.t1sides or {}
	local t2sides = extradata.t2sides or {}
	local t1halfs = extradata.t1halfs or {}
	local t2halfs = extradata.t2halfs or {}

	local team1Scores = {}
	local team2Scores = {}
	for sideIndex in ipairs(t1sides) do
		local side1, side2 = t1sides[sideIndex], t2sides[sideIndex]
		local score1, score2 = t1halfs[sideIndex], t2halfs[sideIndex]
		table.insert(team1Scores, {style = side1 and ('brkts-cs-score-color-'.. side1) or nil, score = score1})
		table.insert(team2Scores, {style = side2 and ('brkts-cs-score-color-'.. side2) or nil, score = score2})
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '85%'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.DetailedScore{score = score(1), partialScores = team1Scores, flipped = false},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game), css = {['flex-grow'] = '1'}},
			MatchSummaryWidgets.DetailedScore{score = score(2), partialScores = team2Scores, flipped = true},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

return CustomMatchSummary

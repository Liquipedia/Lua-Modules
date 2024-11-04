---
-- @Liquipedia
-- wiki=criticalops
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px'})
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Html?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if not game.map then
		return
	end
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	local function score(oppIdx)
		return DisplayHelper.MapScore(game.scores[oppIdx], oppIdx, game.resultType, game.walkover, game.winner)
	end

	-- Teams scores
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

	-- Map Info
	local mapInfo = mw.html.create('div')
	mapInfo	:addClass('brkts-popup-spaced')
			:wikitext('[[' .. game.map .. ']]')
			:css('text-align', 'center')
			:css('padding','5px 2px')
			:css('flex-grow','1')

	if game.resultType == 'np' then
		mapInfo:addClass('brkts-popup-spaced-map-skip')
	elseif game.resultType == 'draw' then
		mapInfo:wikitext('<i>(Draw)</i>')
	end

	-- Build the HTML
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1})
	row:addElement(MatchSummaryWidgets.DetailedScore{score = score(1), partialScores = team1Scores, flipped = false})

	row:addElement(mapInfo)

	row:addElement(MatchSummaryWidgets.DetailedScore{score = score(2), partialScores = team2Scores, flipped = true})
	row:addElement(MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2})

	-- Add Comment
	if not Logic.isEmpty(game.comment) then
		row:addElement(MatchSummaryWidgets.Break{})
		local comment = mw.html.create('div')
		comment :wikitext(game.comment)
				:css('margin', 'auto')
		row:addElement(comment)
	end

	row:addClass('brkts-popup-body-game'):css('font-size', '85%'):css('overflow', 'hidden')

	return row:create()
end

return CustomMatchSummary

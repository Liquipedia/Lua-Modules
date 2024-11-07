---
-- @Liquipedia
-- wiki=clashofclans
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

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

function CustomMatchSummary.createHeader(match)
	local header = MatchSummary.Header()

	local opponentLeft = match.opponents[1]
	local opponentRight = match.opponents[2]

	-- for Bo1 overwritte opponents scores with game score for matchsummary header display
	if match.bestof == 1 and match.games and match.games[1] and
		not match.opponents[1].placement2 and not match.opponents[2].placement2 then

		opponentLeft = Table.merge(match.opponents[1], {score = (match.games[1].scores or {})[1] or 0})
		opponentRight = Table.merge(match.opponents[2], {score = (match.games[1].scores or {})[2] or 0})
	end


	header:leftOpponent(header:createOpponent(match.opponents[1], 'left'))
		:leftScore(header:createScore(opponentLeft))
		:rightScore(header:createScore(opponentRight))
		:rightOpponent(header:createOpponent(match.opponents[2], 'right'))

	return header
end

function CustomMatchSummary._gameScore(game, opponentIndex)
	return mw.html.create('div')
		:css('width', '16px')
		:wikitext(DisplayHelper.MapScore(
			game.scores[opponentIndex],
			opponentIndex,
			game.resultType,
			game.walkover,
			game.winner
		))
end

function CustomMatchSummary._percentage(game, opponentIndex)
	local percentage = game.extradata.percentages[opponentIndex]

	if not percentage then return end

	return mw.html.create('div')
		:css('font-size', '80%')
		:css('width', '48px')
		:wikitext(Abbreviation.make('(' .. percentage .. '%)', 'Average Damage Percentage'))
end

function CustomMatchSummary._time(game, opponentIndex)
	local time = game.extradata.times[opponentIndex]

	if not time then return end

	return mw.html.create('div')
		:css('font-size', '80%')
		:css('width', '40px')
		:wikitext(Abbreviation.make('(' .. os.date('%M:%S', time) .. ')', 'Total Time'))
end

---@param date string
---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return Widget?
function CustomMatchSummary.createGame(date, game, gameIndex)
	if Table.isEmpty(game.scores) then
		return
	end

	local function makeTeamSection(opponentIndex)
		return {
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = opponentIndex},
			CustomMatchSummary._gameScore(game, opponentIndex),
			CustomMatchSummary._percentage(game, opponentIndex),
			CustomMatchSummary._time(game, opponentIndex)
		}
	end

	game.map = 'Game ' .. gameIndex
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

return CustomMatchSummary

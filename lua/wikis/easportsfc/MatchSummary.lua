---
-- @Liquipedia
-- wiki=easportsfc
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibrary = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibrary.OpponentDisplay

local NO_CHECK = '[[File:NoCheck.png|link=]]'

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args)
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp
	local hasSubMatches = Logic.readBool((match.extradata or {}).hassubmatches)

	local games = Array.map(match.games, function(game)
		if hasSubMatches then
			return CustomMatchSummary._createSubMatch(game, match)
		end
		return CustomMatchSummary._createGame(game)
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		games
	)}
end

---@param game MatchGroupUtilGame
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game)
	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '84%', padding = '4px'},
		children = WidgetUtil.collect(
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			DisplayHelper.MapScore(game.opponents[1], game.status),
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game)},
			DisplayHelper.MapScore(game.opponents[2], game.status),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param game MatchGroupUtilGame
---@param match MatchGroupUtilMatch
---@return MatchSummaryRow
function CustomMatchSummary._createSubMatch(game, match)
	local players = CustomMatchSummary._extractPlayersFromGame(game, match)

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '84%', padding = '4px'},
		children = WidgetUtil.collect(
			CustomMatchSummary._players(players[1], 1, game.winner),
			DisplayHelper.MapScore(game.opponents[1], game.status),
			CustomMatchSummary._score(CustomMatchSummary._subMatchPenaltyScore(game, 1)),
			MatchSummaryWidgets.GameCenter{children = ' vs '},
			CustomMatchSummary._score(CustomMatchSummary._subMatchPenaltyScore(game, 2)),
			DisplayHelper.MapScore(game.opponents[2], game.status),
			CustomMatchSummary._players(players[2], 2, game.winner),
			MatchSummaryWidgets.GameComment{children = game.comment}
		)
	}
end

---@param game MatchGroupUtilGame
---@param match MatchGroupUtilMatch
---@return table[][]
function CustomMatchSummary._extractPlayersFromGame(game, match)
	return Array.map(game.opponents, function(opponent, opponentIndex)
		return Array.map(opponent.players, function(player, playerIndex)
			if not player.played then return end
			local matchPlayer = match.opponents[opponentIndex].players[playerIndex]
			return matchPlayer or {
				displayName = player.displayname,
				pageName = player.name,
			}
		end)
	end)
end

---@param score number|string|nil
---@return Html?
function CustomMatchSummary._score(score)
	if not score then return end

	return mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(score)
end

---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return string
function CustomMatchSummary._subMatchPenaltyScore(game, opponentIndex)
	local scores = (game.extradata or {}).penaltyscores

	if not scores then return NO_CHECK end

	return Abbreviation.make{
		text = '(' .. (scores[opponentIndex] or 0) .. ')',
		title = 'Penalty shoot-out',
	}
end

---@param players table[]
---@param opponentIndex integer
---@param winner integer
---@return Html
function CustomMatchSummary._players(players, opponentIndex, winner)
	local flip = opponentIndex == 1

	return mw.html.create('div')
		:addClass(winner == opponentIndex and 'bg-win' or winner == 0 and 'bg-draw' or nil)
		:css('align-items', 'center')
		:css('border-radius', flip and '0 12px 12px 0' or '12px 0 0 12px')
		:css('padding', '2px 8px')
		:css('text-align', flip and 'right' or 'left')
		:css('width', '35%')
		:node(OpponentDisplay.BlockPlayers{
			opponent = {players = players},
			overflow = 'ellipsis',
			showLink = true,
		})
end

return CustomMatchSummary

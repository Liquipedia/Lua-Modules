---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay
local PlayerDisplay = require('Module:Player/Display')

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '350px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	CustomMatchSummary._fixGameOpponents(match.games, match.opponents)

	local isTeamMatch = Array.any(match.opponents, function(opponent)
		return opponent.type == Opponent.team
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		Array.map(match.games, function (game, gameIndex)
			if isTeamMatch and String.startsWith(game.map or '', 'Submatch') then
				return CustomMatchSummary._createSubmatch(game)
			else
				return CustomMatchSummary._createGame(isTeamMatch, game, gameIndex)
			end
		end)
	)}
end

---@param games MatchGroupUtilGame
---@param opponents standardOpponent[]
function CustomMatchSummary._fixGameOpponents(games, opponents)
	Array.forEach(games, function (game)
		game.opponents = Array.map(game.opponents, function (opponent, opponentIndex)
			return Table.merge(opponent, {
				players = Array.map(game.opponents[opponentIndex].players,function (player, playerIndex)
					if Logic.isEmpty(player) then return nil end
					return Table.merge(opponents[opponentIndex].players[playerIndex] or {}, player)
				end)
			})
		end)
	end)
end

---@param game MatchGroupUtilGame
---@return Widget
function CustomMatchSummary._createSubmatch(game)
	local opponents = game.opponents or {{}, {}}
	local createOpponent = function(opponentIndex)
		local players = (opponents[opponentIndex] or {}).players or {}
		if Logic.isEmpty(players) then
			players = Opponent.tbd(Opponent.solo).players
		end
		return OpponentDisplay.BlockOpponent{
			flip = opponentIndex == 1,
			opponent = {players = players, type = Opponent.partyTypes[math.max(#players, 1)]},
			showLink = true,
			overflow = 'ellipsis',
		}
	end

	---@param opponentIndex any
	---@return Html
	local createScore = function(opponentIndex)
		local isWinner = opponentIndex == game.winner or game.resultType == 'draw'
		if game.resultType == 'default' then
			return OpponentDisplay.BlockScore{
				isWinner = isWinner,
				scoreText = isWinner and 'W' or string.upper(game.walkover),
			}
		end

		local score = game.resultType ~= 'np' and (game.scores or {})[opponentIndex] or nil
		return OpponentDisplay.BlockScore{
			isWinner = isWinner,
			scoreText = score,
		}
	end

	return HtmlWidgets.Div{
		classes = {'brkts-popup-header-dev'},
		css = {['justify-content'] = 'center', margin = 'auto'},
		children = WidgetUtil.collect(
			HtmlWidgets.Div{
				classes = {'brkts-popup-header-opponent', 'brkts-popup-header-opponent-left'},
				children = {
					createOpponent(1),
					createScore(1):addClass('brkts-popup-header-opponent-score-left'),
				},
			},
			HtmlWidgets.Div{
				classes = {'brkts-popup-header-opponent', 'brkts-popup-header-opponent-right'},
				children = {
					createScore(2):addClass('brkts-popup-header-opponent-score-right'),
					createOpponent(2),
				},
			}
		)
	}
end

---@param isTeamMatch boolean
---@param game MatchGroupUtilGame
---@param gameIndex number
---@return Widget
function CustomMatchSummary._createGame(isTeamMatch, game, gameIndex)
	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {padding = '4px', ['min-height'] = '24px'},
		children = WidgetUtil.collect(
			CustomMatchSummary._displayOpponents(isTeamMatch, game.opponents[1].players, true),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{css = {['font-size'] = '80%'}, children = 'Game ' .. gameIndex},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			CustomMatchSummary._displayOpponents(isTeamMatch, game.opponents[2].players)
		)
	}
end

---@param isTeamMatch boolean
---@param players table[]
---@param flip boolean?
---@return Html?
function CustomMatchSummary._displayOpponents(isTeamMatch, players, flip)
	local playerDisplays = Array.map(players, function (player)
		local char = HtmlWidgets.Div{
			classes = {'brkts-champion-icon'},
			children = MatchSummaryWidgets.Character{
				character = player.class,
				showName = not isTeamMatch,
				flipped = flip,
			}
		}
		return HtmlWidgets.Div{
			css = {
				display = 'flex',
				['flex-direction'] = flip and 'row-reverse' or 'row',
				gap = '2px',
				width = '100%'
			},
			children = {
				char,
				isTeamMatch and PlayerDisplay.BlockPlayer{player = player, flip = flip} or nil,
			},
		}
	end)

	return MatchSummaryWidgets.GameTeamWrapper{
		flipped = flip,
		children = playerDisplays
	}
end

return CustomMatchSummary

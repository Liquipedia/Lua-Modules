---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Tournament = Lua.import('Module:Tournament')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local SPAN_SLASH = Html.Span{classes = {'slash'}, children = '/'}

---@class ValorantMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.mapDisplay,
}

local ValorantMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@class ValorantMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {
	GameRow = ValorantMatchSummaryGameRow,
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(
		CustomMatchSummary,
		args,
		{
			width = '500px',
			mapVetoPreprocessOptions = {useLpdb = true},
			showDetail = function (match)
				local input = Logic.readBoolOrNil(args.showDetail)
				if input ~= nil then
					return input
				end
				return HighlightConditions.tournament(Tournament.partialTournamentFromMatch(match))
			end,
		}
	)
end

---@param game MatchGroupUtilGame
---@return boolean
function CustomMatchSummary.gameFilter(game)
	return Logic.isNotEmpty(game.map)
end

---@private
---@param game MatchGroupUtilGame
---@param opponentIndex integer
---@return table[]
function GameRowComponentProps._makePartialScores(game, opponentIndex)
	local extradata = game.extradata or {}
	local firstSide = extradata.t1firstside or ''
	local oppositeSide = GameRowComponentProps._getOppositeSide(firstSide)
	local halves = extradata['t' .. opponentIndex .. 'halfs'] or {}
	if opponentIndex == 2 then
		firstSide, oppositeSide = oppositeSide, firstSide
	end
	return {
		{style = 'brkts-valorant-score-color-' .. firstSide, score = halves[firstSide]},
		{style = 'brkts-valorant-score-color-' .. oppositeSide, score = halves[oppositeSide]},
		{style = 'brkts-valorant-score-color-' .. firstSide, score = halves['ot' .. firstSide]},
		{style = 'brkts-valorant-score-color-' .. oppositeSide, score = halves['ot' .. oppositeSide]},
	}
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode[]
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local flipped = opponentIndex == 2
	local characters = Array.map((game.opponents[opponentIndex] or {}).players or {}, Operator.property('agent'))
	return {
		MatchSummaryWidgets.Characters{characters = characters, flipped = flipped, hideOnMobile = true},
		MatchSummaryWidgets.DetailedScore{
			score = MatchSummaryWidgets.GameRow.scoreDisplay(game, opponentIndex),
			partialScores = GameRowComponentProps._makePartialScores(game, opponentIndex)
		}
	}
end

---@param side string?
---@return string
function GameRowComponentProps._getOppositeSide(side)
	if Logic.isEmpty(side) then
		return ''
	elseif side == 'atk' then
		return 'def'
	end
	return 'atk'
end

---@param game MatchGroupUtilGame
---@param index integer
---@return VNode?
function CustomMatchSummary.GameDetail(game, index)
	if Array.all(game.opponents, function (gameOpponent)
		return Logic.isDeepEmpty(gameOpponent.players)
	end) then
		return nil
	end

	local gamePlayers = Array.map(game.opponents, function (gameOpponent)
		return CustomMatchSummary._sortGamePlayersByAcs(gameOpponent.players)
	end)

	return MatchSummaryWidgets.GameDetail{
		game = game,
		gameIndex = index,
		overview = Html.Fragment{children = {
			DisplayHelper.Map(game),
			SPAN_SLASH,
			game.length,
		}},
		children = WidgetUtil.collect(
			CustomMatchSummary._createOpponentDetail(game, gamePlayers[1], 1),
			CustomMatchSummary._createOpponentDetail(game, gamePlayers[2], 2)
		),
	}
end

---@private
---@param players table[]
---@return table[]
function CustomMatchSummary._sortGamePlayersByAcs(players)
	return Array.sortBy(
		Array.filter(players, Logic.isNotEmpty),
		function (gamePlayer)
			return gamePlayer.acs
		end,
		function (a, b)
			return (a or -math.huge) < (b or -math.huge)
		end
	)
end

---@private
---@param game MatchGroupUtilGame
---@param gamePlayersOfTeam table[]
---@param gameOpponentIndex integer
---@return VNode
function CustomMatchSummary._createOpponentDetail(game, gamePlayersOfTeam, gameOpponentIndex)
	return Html.Div{
		classes = {'brkts-popup-game-detail-player-container'},
		children = Array.map(gamePlayersOfTeam, function (gamePlayer)
			local kda = {gamePlayer.kills, gamePlayer.deaths, gamePlayer.assists}
			local stats = Html.Div{children = Array.interleave(kda, SPAN_SLASH)}
			return Html.Div{
				classes = {
					'brkts-popup-game-detail-player',
					gameOpponentIndex == 2 and 'flipped' or nil,
				},
				children = {
					MatchSummaryWidgets.Character{
						classes = {'brkts-popup-game-detail-player-character'},
						date = game.date,
						flipped = gameOpponentIndex == 2,
						showName = false,
						size = '24px',
						character = gamePlayer.agent
					},
					Link{link = gamePlayer.player, children = gamePlayer.displayName},
					Html.Div{
						classes = {'brkts-popup-game-detail-player-stats'},
						children = stats
					},
				}
			}
		end)
	}
end

return CustomMatchSummary

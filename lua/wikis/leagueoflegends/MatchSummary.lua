---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local InGameRoles = Lua.import('Module:InGameRoles', {loadData = true})
local HighlightConditions = Lua.import('Module:HighlightConditions')
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')
local Tournament = Lua.import('Module:Tournament')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local Html = Lua.import('Module:Widget/Html')
local Link = Lua.import('Module:Widget/Basic/Link')

local MAX_NUM_BANS = 5
local NUM_HEROES_PICK = 5
local SIDE_COLORS = {
	red = 'var( --clr-cinnabar-40 )',
	blue = 'var( --clr-sapphire-40 )',
}
local STATUS_NOT_PLAYED = 'notplayed'
local SPAN_SLASH = Html.Span{classes = {'slash'}, children = '/'}

---@class LoLMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.lengthDisplay,
}

local LoLMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@class LoLCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {
	GameRow = LoLMatchSummaryGameRow,
}

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(
		CustomMatchSummary,
		args,
		{
			width = '400px',
			maxBans = MAX_NUM_BANS,
			showDetail = function (match)
				local input = Logic.readBoolOrNil(args.showDetail)
				if input ~= nil then
					return input
				end
				return HighlightConditions.tournament(Tournament.partialTournamentFromMatch(match))
			end
		}
	)
end

---@param game MatchGroupUtilGame
---@return boolean
function CustomMatchSummary.gameFilter(game)
	return game.status ~= STATUS_NOT_PLAYED
end

---@param props MatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local game = props.game
	local extradata = game.extradata or {}

	return MatchSummaryWidgets.Characters{
		flipped = opponentIndex == 2,
		characters = MatchSummary.buildCharacterList(
			extradata, 'team' .. opponentIndex .. 'champion', NUM_HEROES_PICK
		),
		bg = 'brkts-popup-side-color brkts-popup-side-color--' .. (extradata['team' .. opponentIndex .. 'side'] or ''),
		date = game.date,
	}
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
		return CustomMatchSummary._sortGamePlayersByRole(gameOpponent.players)
	end)

	local maxDamage = Array.reduce(
		Array.flatten(gamePlayers),
		function (aggregate, gamePlayer)
			return MathUtil.nilSafeMax(aggregate, gamePlayer.damagedone)
		end,
		-math.huge
	)

	return MatchSummaryWidgets.GameDetail{
		game = game,
		gameIndex = index,
		overview = game.length,
		children = Array.mapRange(1, #game.opponents, function (opponentIndex)
			return CustomMatchSummary._createOpponentDetail(game, gamePlayers[opponentIndex], opponentIndex, maxDamage)
		end),
	}
end

---@private
---@param players table[]
---@return table[]
function CustomMatchSummary._sortGamePlayersByRole(players)
	return Array.sortBy(
		Array.filter(players, Logic.isNotEmpty),
		function (gamePlayer)
			return gamePlayer.role
		end,
		function (a, b)
			return InGameRoles[a].sortOrder < InGameRoles[b].sortOrder
		end
	)
end

---@private
---@param game MatchGroupUtilGame
---@param gamePlayersOfTeam table[]
---@param gameOpponentIndex integer
---@param maxDamage number?
---@return VNode
function CustomMatchSummary._createOpponentDetail(game, gamePlayersOfTeam, gameOpponentIndex, maxDamage)
	local side = game.extradata['team' .. gameOpponentIndex .. 'side']

	---@param damageDone number
	---@return VNode?
	local function buildDamageBar(damageDone)
		if damageDone == nil or maxDamage == -math.huge then
			return
		end
		local damageRatio = damageDone / maxDamage
		return Html.Div{
			classes = {'damage-bar'},
			css = {
				['--left-bar-color'] = gameOpponentIndex == 1 and SIDE_COLORS[side] or nil,
				['--left-bar-length'] = MathUtil.formatPercentage(
					gameOpponentIndex == 1 and damageRatio or (1 - damageRatio)
				),
				['--right-bar-color'] = gameOpponentIndex == 2 and SIDE_COLORS[side] or nil,
			}
		}
	end

	return Html.Div{
		classes = {'brkts-popup-game-detail-player-container'},
		children = Array.map(gamePlayersOfTeam, function (gamePlayer)
			local kda = {gamePlayer.kills, gamePlayer.deaths, gamePlayer.assists}
			local stats = Array.interleave({
				Html.Div{children = Array.interleave(kda, SPAN_SLASH)},
				gamePlayer.damagedone and Html.Div{children = {
					'(',
					string.format('%.1fK', gamePlayer.damagedone / 1000),
					')'
				}} or nil
			}, ' ')
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
						character = gamePlayer.character
					},
					Link{link = gamePlayer.player, children = gamePlayer.displayName},
					Html.Div{
						classes = {'brkts-popup-game-detail-player-stats'},
						children = stats
					},
					buildDamageBar(gamePlayer.damagedone)
				}
			}
		end)
	}
end

return CustomMatchSummary

---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local InGameRoles = Lua.import('Module:InGameRoles', {loadData = true})
local Logic = Lua.import('Module:Logic')
local MathUtil = Lua.import('Module:MathUtil')
local Operator = Lua.import('Module:Operator')

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
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', maxBans = MAX_NUM_BANS})
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

	local maxDamage = Array.reduce(
		Array.map(game.opponents, function (gameOpponent)
			return Array.reduce(
				Array.map(gameOpponent.players, Operator.property('damagedone')),
				MathUtil.nilSafeMax
			)
		end),
		MathUtil.nilSafeMax
	)

	return MatchSummaryWidgets.GameDetail{
		game = game,
		gameIndex = index,
		overview = game.length,
		children = Array.mapRange(1, #game.opponents, function (opponentIndex)
			return CustomMatchSummary._createOpponentDetail(game, opponentIndex, maxDamage)
		end),
	}
end

---@private
---@param game MatchGroupUtilGame
---@param gameOpponentIndex integer
---@param maxDamage number?
---@return VNode
function CustomMatchSummary._createOpponentDetail(game, gameOpponentIndex, maxDamage)
	local gameOpponent = game.opponents[gameOpponentIndex]
	local side = game.extradata['team' .. gameOpponentIndex .. 'side']
	local gamePlayers = Array.sortBy(
		Array.filter(gameOpponent.players, Logic.isNotEmpty),
		function (gamePlayer)
			return gamePlayer.role
		end,
		function (a, b)
			return InGameRoles[a].sortOrder < InGameRoles[b].sortOrder
		end
	)

	---@param damageDone number
	---@return VNode?
	local function buildDamageBar(damageDone)
		if damageDone == nil or maxDamage == nil then
			return
		end
		local damageRatio = damageDone / maxDamage
		return Html.Div{
			classes = {'damage-bar'},
			css = {
				['--left-bar-color'] = gameOpponentIndex == 1 and SIDE_COLORS[side] or 'transparent',
				['--left-bar-length'] = MathUtil.formatPercentage(
					gameOpponentIndex == 1 and damageRatio or (1 - damageRatio)
				),
				['--right-bar-color'] = gameOpponentIndex == 2 and SIDE_COLORS[side] or 'transparent',
				['--right-bar-length'] = MathUtil.formatPercentage(
					gameOpponentIndex == 2 and damageRatio or (1 - damageRatio)
				),
				height = '0.25rem',
				width = '90%'
			}
		}
	end

	return Html.Div{
		classes = {'brkts-popup-game-detail-player-container'},
		children = Array.map(gamePlayers, function (gamePlayer)
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
					Html.Div{
						css = {
							['align-self'] = 'center',
							['grid-row'] = 'span 3'
						},
						children = MatchSummaryWidgets.Character{
							date = game.date,
							flipped = gameOpponentIndex == 2,
							showName = false,
							size = '24px',
							character = gamePlayer.character
						}
					},
					Link{link = gamePlayer.player, children = gamePlayer.displayName},
					Html.Div{
						css = {
							display = 'flex',
							['flex-direction'] = gameOpponentIndex == 2 and 'row-reverse' or nil,
							gap = '0.25rem',
						},
						children = gameOpponentIndex == 1 and stats or Array.reverse(stats)
					},
					buildDamageBar(gamePlayer.damagedone)
				}
			}
		end)
	}
end

return CustomMatchSummary

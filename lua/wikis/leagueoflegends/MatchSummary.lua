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
local Tournament = Lua.import('Module:Tournament')

local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local Html = Lua.import('Module:Widget/Html')
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local Link = Lua.import('Module:Widget/Basic/Link')
local WidgetUtil = Lua.import('Module:Widget/Util')

local EMPTY_PLACEHOLDER = Html.Div{}
local GOLD_ICON = IconFa{iconName = 'gold', hover = 'Gold'}
local MAX_NUM_BANS = 5
local NUM_HEROES_PICK = 5
local SIDE_COLORS = {
	red = 'var( --clr-cinnabar-40 )',
	blue = 'var( --clr-sapphire-40 )',
}
local STATUS_NOT_PLAYED = 'notplayed'
local SPAN_SLASH = Html.Span{classes = {'slash'}, children = '/'}
local WINNER_LEFT = IconFa{iconName = 'winner_left'}
local WINNER_RIGHT = IconFa{iconName = 'winner_right'}

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

	local hasCenterColumn = maxDamage > -math.huge and #gamePlayers[1] == #gamePlayers[2] and #gamePlayers[1] == 5

	return MatchSummaryWidgets.GameDetail{
		hasCenterColumn = hasCenterColumn,
		game = game,
		gameIndex = index,
		overview = game.length,
		children = WidgetUtil.collect(
			CustomMatchSummary._createOpponentDetail(game, gamePlayers[1], 1, maxDamage),
			hasCenterColumn and CustomMatchSummary._createPlayerDiff(gamePlayers) or nil,
			CustomMatchSummary._createOpponentDetail(game, gamePlayers[2], 2, maxDamage)
		),
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
					CustomMatchSummary._formatValue(gamePlayer.damagedone),
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

---@private
---@param value number
---@return number|string
function CustomMatchSummary._formatValue(value)
	if math.abs(value) < 1000 then
		return value
	end
	return string.format('%.1fK', value / 1000)
end

---@private
---@param diff number
---@return VNode|VNode[]
function CustomMatchSummary._createGoldDiffDisplay(diff)
	if diff == 0 then
		return Html.Div{children = '-'}
	end
	return {
		diff > 0 and WINNER_LEFT or EMPTY_PLACEHOLDER,
		Html.Div{children = CustomMatchSummary._formatValue(math.abs(diff))},
		diff < 0 and WINNER_RIGHT or EMPTY_PLACEHOLDER,
	}
end

---@private
---@param players table[][]
---@return VNode
function CustomMatchSummary._createPlayerDiff(players)
	return Html.Div{
		classes = {'stat-diff'},
		children = Array.mapRange(1, NUM_HEROES_PICK, function (index)
			local p1Gold = (players[1][index].gold or 0)
			local p2Gold = (players[2][index].gold or 0)

			local goldDiff = p1Gold - p2Gold

			return Html.Div{
				children = CustomMatchSummary._createGoldDiffDisplay(goldDiff)
			}
		end)
	}
end

return CustomMatchSummary

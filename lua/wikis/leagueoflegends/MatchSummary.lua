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
local String = Lua.import('Module:StringUtils')

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

---@class LoLCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class LoLMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.lengthDisplay,
}

local LoLMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px'})
end

---@param match MatchGroupUtilMatch
---@return VNode[]
function CustomMatchSummary.createBody(match)
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)

	return {
		MatchSummaryWidgets.GamesContainer{
			children = Array.map(match.games, function (game, gameIndex)
				if game.status == STATUS_NOT_PLAYED then
					return
				end
				return LoLMatchSummaryGameRow{game = game, gameIndex = gameIndex}
			end)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.CharacterBanTable{bans = characterBansData, date = match.date}
	}
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

---@param props MatchSummaryGameRowProps
---@return boolean
function GameRowComponentProps.hasDetail(props)
	return Array.any(props.game.opponents, function (gameOpponent)
		return Logic.isNotDeepEmpty(gameOpponent.players)
	end)
end

---@param props MatchSummaryGameRowProps
---@return VNode
function GameRowComponentProps.createGameDetail(props)
	local game = props.game
	return Html.Div{
		css = {
			display = 'grid',
			['column-gap'] = '0.5rem',
			['grid-template-columns'] = 'min-content 1fr 1fr min-content'
		},
		children = Array.map(game.opponents, function (gameOpponent, gameOpponentIndex)
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
			local maxDamage = Array.max(
				Array.map(gamePlayers, Operator.property('damagedone'))
			)
			return Html.Div{
				css = {
					display = 'grid',
					['grid-column'] = 'span 2',
					['grid-template-columns'] = 'subgrid',
					['row-gap'] = '0.25rem',
				},
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
					local damageRatio = maxDamage ~= nil and (gamePlayer.damagedone / maxDamage) or nil
					return Html.Div{
						css = {
							display = 'grid',
							['grid-column'] = '1 / -1',
							['grid-template-columns'] = 'subgrid',
							['justify-items'] = 'start',
							direction = gameOpponentIndex == 2 and 'rtl' or nil,
						},
						children = {
							MatchSummaryWidgets.Character{
								date = game.date,
								flipped = gameOpponentIndex == 2,
								showName = false,
								size = '16px',
								character = gamePlayer.character
							},
							Link{link = gamePlayer.player, children = gamePlayer.displayName},
							Html.Div{
								css = {
									display = 'flex',
									['flex-direction'] = gameOpponentIndex == 2 and 'row-reverse' or nil,
									gap = '0.25rem',
									['grid-column'] = '1 / -1',
								},
								children = gameOpponentIndex == 1 and stats or Array.reverse(stats)
							},
							maxDamage and Html.Div{
								css = {
									['grid-column'] = '1 / -1',
									background = String.interpolate(
										'linear-gradient(to right, ${leftBarColor} ${leftBarLength}, ${rightBarColor} ${leftBarLength} ${rightBarLength})',
										{
											leftBarColor = gameOpponentIndex == 1 and SIDE_COLORS[side] or 'transparent',
											leftBarLength = MathUtil.formatPercentage(
												gameOpponentIndex == 1 and damageRatio or (1 - damageRatio)
											),
											rightBarColor = gameOpponentIndex == 2 and SIDE_COLORS[side] or 'transparent',
											rightBarLength = MathUtil.formatPercentage(
												gameOpponentIndex == 2 and damageRatio or (1 - damageRatio)
											),
										}
									),
									height = '0.25rem',
									width = '90%'
								}
							} or nil
						}
					}
				end)
			}
		end)
	}
end

return CustomMatchSummary

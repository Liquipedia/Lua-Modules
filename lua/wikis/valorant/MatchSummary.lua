---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local PlayerDisplay = Lua.import('Module:Player/Display/Custom')

local MatchSummary = Lua.import('Module:MatchSummary/Base')

local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class ValorantMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class ValorantMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {
	createGameOverview = MatchSummaryWidgets.GameRow.mapDisplay,
}

local ValorantMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(GameRowComponentProps)

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '500px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return VNode[]
function CustomMatchSummary.createBody(match)
	return {
		MatchSummaryWidgets.GamesContainer{
			children = WidgetUtil.collect(
				Array.map(match.games, function (game, gameIndex)
					if Logic.isEmpty(game.map) then
						return
					end
					return ValorantMatchSummaryGameRow{game = game, gameIndex = gameIndex}
				end),
				CustomMatchSummary._createSkirmishDisplay(match.extradata.skirmish)
			)
		},
		MatchSummaryWidgets.Mvp(match.extradata.mvp),
		MatchSummaryWidgets.MapVeto(
			MatchSummary.preProcessMapVeto(match.extradata.mapveto, {useLpdb = true})
		)
	}
end

---@param skirmishData ValorantSkirmishResult
---@return VNode?
function CustomMatchSummary._createSkirmishDisplay(skirmishData)
	if Logic.isEmpty(skirmishData) then
		return
	end
	local players = Array.map(
		skirmishData.players,
		function (player)
			---@type standardPlayer
			return {
				displayName = player.displayname,
				pageName = player.name,
				flag = player.flag,
			}
		end
	)
	return Html.Div{
		classes = {'brkts-popup-body-grid-row'},
		children = {
			Html.B{
				css = {
					['grid-column'] = '1 / -1',
					['justify-self'] = 'center',
				},
				children = 'Skirmish Side Selection Result'
			},
			Html.Div{
				classes = {'brkts-popup-body-grid-row-detail'},
				children = {
					Html.Span{
						css = {
							['justify-self'] = 'end',
						},
						children = PlayerDisplay.InlinePlayer{
							flip = true,
							player = players[1],
						}
					},
					Html.Div{
						css = {
							display = 'grid',
							['grid-template-columns'] = '1fr min-content 1fr',
							gap = '0.25rem',
							['justify-self'] = 'center',
						},
						children = Array.interleave(
							Array.map(
								skirmishData.scores,
								function (score, scoreIndex)
									return Html.Span{
										css = skirmishData.winner == scoreIndex and {
											['font-weight'] = 'bold'
										} or nil,
										children = score,
									}
								end
							),
							Html.Span{children = '&ndash;'}
						)
					},
					Html.Span{
						css = {
							['justify-self'] = 'start',
						},
						children = PlayerDisplay.InlinePlayer{
							player = players[2],
						}
					},
				}
			},
		}
	}
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

return CustomMatchSummary

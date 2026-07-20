---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local Html = Lua.import('Module:Widget/Html')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display')

---@class FightersCustomMatchSummary: CustomMatchSummaryInterface
local CustomMatchSummary = {}

---@class FightersMatchSummaryGameRowComponentProps: MatchSummaryGameRowComponentProps
local GameRowComponentProps = {}

---@class FightersMatchSummaryGameRowProps: MatchSummaryGameRowProps
---@field gameData string?
---@field matchOpponents standardOpponent[]
---@field soloMode boolean

---@type Component<FightersMatchSummaryGameRowProps>
local FightersMatchSummaryGameRow = MatchSummaryWidgets.GameRow.createComponent(
	GameRowComponentProps, {allowWrappingInOverview = true}
)

---@param args table
---@return Renderable
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {
		width = CustomMatchSummary._determineWidth,
		teamStyle = 'bracket',
	})
end

---@param match MatchGroupUtilMatch
---@return string
function CustomMatchSummary._determineWidth(match)
	return CustomMatchSummary._isSolo(match) and '400px' or '550px'
end

---@param match MatchGroupUtilMatch
---@return boolean
function CustomMatchSummary._isSolo(match)
	return Array.all(match.opponents, function (opponent)
		return Opponent.isOpponent(opponent) and opponent.type == Opponent.solo
	end)
end

---@param match MatchGroupUtilMatch
---@return VNode
function CustomMatchSummary.createBody(match)
	return MatchSummaryWidgets.GamesContainer{
		children = Array.map(match.games, function (game, gameIndex)
			if Array.all(game.opponents, function(opponent) return Logic.isDeepEmpty(opponent.players) end) then
				return
			end
			return FightersMatchSummaryGameRow{
				game = game,
				gameIndex = gameIndex,
				gameData = match.game,
				matchOpponents = match.opponents,
				soloMode = CustomMatchSummary._isSolo(match),
			}
		end)
	}
end

---@param game MatchGroupUtilGame
---@param matchOpponents standardOpponent[]
---@param opponentIndex integer
---@return {player: standardPlayer, characters: string[]}[]
function CustomMatchSummary.fetchCharactersOfPlayers(game, matchOpponents, opponentIndex)
	return Array.map(game.opponents[opponentIndex].players, function (players, index)
		if players.characters then
			local characters = Array.map(players.characters, Operator.property('name'))
			return {player = matchOpponents[opponentIndex].players[index], characters = characters}
		end
	end)
end

---@param props FightersMatchSummaryGameRowProps
---@return string
function GameRowComponentProps.createGameOverview(props)
	local game = props.game
	local scores = Array.map(game.opponents, function(opponent)
		return DisplayHelper.MapScore(opponent, game.status)
	end)

	return table.concat(scores, '&nbsp;-&nbsp;')
end

---@param props FightersMatchSummaryGameRowProps
---@param opponentIndex integer
---@return VNode[]?
function GameRowComponentProps.createGameOpponentView(props, opponentIndex)
	local players = CustomMatchSummary.fetchCharactersOfPlayers(props.game, props.matchOpponents, opponentIndex)
	local reverse = opponentIndex == 1
	local CharacterIcons = Lua.import('Module:CharacterIcons/' .. (props.gameData or ''), {loadData = true})

	---@param showCharacterName boolean
	---@param character string
	---@return VNode
	local function createCharacterDisplay(showCharacterName, character)
		local children = WidgetUtil.collect(
			CharacterIcons[character],
			showCharacterName and {
				'&nbsp;',
				character
			} or nil
		)
		return Html.Div{
			classes = {'brkts-popup-body-element-thumbs'},
			children = reverse and Array.reverse(children) or children
		}
	end

	if Logic.isDeepEmpty(players) then
		return
	elseif props.soloMode then
		local player = players[1]
		return Array.map(player.characters, FnUtil.curry(createCharacterDisplay, true))
	end
	return Array.map(players, function (player)
		if Logic.isEmpty(player.characters) then
			return
		end
		return Html.Div{
			css = {
				display = 'flex',
				['flex-direction'] = 'row' .. (reverse and '-reverse' or ''),
			},
			children = Array.interleave(
				WidgetUtil.collect(
					Array.map(player.characters, FnUtil.curry(createCharacterDisplay, false)),
					PlayerDisplay.BlockPlayer{player = player.player, flip = reverse}
				),
				'&nbsp;'
			)
		}
	end)
end

---@param props FightersMatchSummaryGameRowProps
---@param opponentIndex integer
---@return HtmlStyleProps
function GameRowComponentProps.getGameOpponentViewCss(props, opponentIndex)
	local reverse = opponentIndex == 1

	return {
		['align-self'] = 'center',
		['flex-direction'] = 'column',
		['align-items'] = reverse and 'flex-end' or 'flex-start',
	}
end

return CustomMatchSummary

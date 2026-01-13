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
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local Opponent = Lua.import('Module:Opponent/Custom')
local PlayerDisplay = Lua.import('Module:Player/Display')

local CustomMatchSummary = {}

---@param args table
---@return Html
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
		if not Opponent.isOpponent(opponent) then
			return false
		end
		return opponent.type == Opponent.solo
	end)
end

---@param match MatchGroupUtilMatch
---@return Widget[]
function CustomMatchSummary.createBody(match)
	local games = Array.map(match.games, function(game)
		return CustomMatchSummary._createStandardGame(game, {
			opponents = match.opponents,
			game = match.game,
			soloMode = CustomMatchSummary._isSolo(match),
		})
	end)

	return WidgetUtil.collect(
		games
	)
end

---@param game MatchGroupUtilGame
---@param matchOpponents standardOpponent[]
---@param teamIdx integer
---@return {player: standardPlayer, characters: string[]}[]
function CustomMatchSummary.fetchCharactersOfPlayers(game, matchOpponents, teamIdx)
	return Array.map(game.opponents[teamIdx].players, function (players, index)
		if players.characters then
			local characters = Array.map(players.characters, Operator.property('name'))
			return {player = matchOpponents[teamIdx].players[index], characters = characters}
		end
	end)
end

---@param game MatchGroupUtilGame
---@param props {game: string?, soloMode: boolean, opponents: table[]}
---@return Widget?
function CustomMatchSummary._createStandardGame(game, props)
	if not game or Array.all(game.opponents, function(opponent) return Logic.isDeepEmpty(opponent.players) end) then
		return
	end

	local scores = Array.map(game.opponents, function(opponent)
		return DisplayHelper.MapScore(opponent, game.status)
	end)

	local scoreDisplay = table.concat(scores, '&nbsp;-&nbsp;')

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {
			['align-items'] = 'center',
			gap = '0.5rem',
		},
		children = WidgetUtil.collect(
			CustomMatchSummary._createCharacterDisplay(
				CustomMatchSummary.fetchCharactersOfPlayers(game, props.opponents, 1),
				props.game,
				true,
				props.soloMode
			),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{children = scoreDisplay, css = {['flex-grow'] = 1}},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			CustomMatchSummary._createCharacterDisplay(
				CustomMatchSummary.fetchCharactersOfPlayers(game, props.opponents, 2),
				props.game,
				false,
				props.soloMode
			)
		)
	}
end

---@param players {player: standardPlayer, characters: string[]}[]
---@param game string?
---@param reverse boolean?
---@param soloMode boolean?
---@return Widget
function CustomMatchSummary._createCharacterDisplay(players, game, reverse, soloMode)
	local CharacterIcons = Lua.import('Module:CharacterIcons/' .. (game or ''), {loadData = true})

	---@param showCharacterName boolean
	---@param character string
	---@return Widget
	local function createCharacterDisplay(showCharacterName, character)
		local children = WidgetUtil.collect(
			CharacterIcons[character],
			showCharacterName and {
				'&nbsp;',
				character
			} or nil
		)
		return HtmlWidgets.Div{
			classes = {'brkts-popup-body-element-thumbs'},
			children = reverse and Array.reverse(children) or children
		}
	end

	---@return Widget|Widget[]?
	local function buildPlayerDisplay()
		if Logic.isDeepEmpty(players) then
			return
		elseif soloMode then
			local player = players[1]
			return Array.map(player.characters, FnUtil.curry(createCharacterDisplay, true))
		end
		return Array.map(players, function (player)
			if Logic.isEmpty(player.characters) then
				return
			end
			return HtmlWidgets.Div{
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

	return HtmlWidgets.Div{
		css = {
			display = 'inline-flex',
			flex = '2 1 30%',
			['flex-direction'] = 'column',
			gap = '0.25rem',
			['align-items'] = reverse and 'flex-end' or nil,
		},
		children = buildPlayerDisplay()
	}
end

return CustomMatchSummary

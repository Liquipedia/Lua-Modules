---
-- @Liquipedia
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local DateExt = Lua.import('Module:Date/Ext')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = Lua.import('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
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
	if type(match.opponents[1]) ~= 'table' or type(match.opponents[2]) ~= 'table' then
		return false
	end
	return match.opponents[1].type == Opponent.solo and match.opponents[2].type == Opponent.solo
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	local games = Array.map(match.games, function(game)
		return CustomMatchSummary._createStandardGame(game, {
			opponents = match.opponents,
			game = match.game,
			soloMode = CustomMatchSummary._isSolo(match),
		})
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		games
	)}
end

---@param game MatchGroupUtilGame
---@param matchOpponents table[]
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
		css = {['font-size'] = '0.75rem', padding = '4px'},
		children = WidgetUtil.collect(
			CustomMatchSummary._createCharacterDisplay(
				CustomMatchSummary.fetchCharactersOfPlayers(game, props.opponents, 1),
				props.game,
				false,
				not props.soloMode
			),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{children = scoreDisplay, css = {['flex-grow'] = 1}},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			CustomMatchSummary._createCharacterDisplay(
				CustomMatchSummary.fetchCharactersOfPlayers(game, props.opponents, 2),
				props.game,
				true,
				not props.soloMode
			)
		)
	}
end

---@param players {player: standardPlayer, characters: string[]}[]
---@param game string?
---@param reverse boolean?
---@param displayPlayerNames boolean?
---@return Html
function CustomMatchSummary._createCharacterDisplay(players, game, reverse, displayPlayerNames)
	local CharacterIcons = Lua.import('Module:CharacterIcons/' .. (game or ''), {loadData = true})
	local wrapper = mw.html.create('div'):css('flex-basis', '40%')

	if Logic.isDeepEmpty(players) then
		return wrapper
	end

	local playerDisplays = Array.map(players, function (player)
		local characters = player.characters
		if #characters == 0 then
			return
		end
		local playerWrapper = mw.html.create('div')
			:css('display', 'flex')
			:css('flex-direction', reverse and 'row' or 'row-reverse')
		local playerNode = PlayerDisplay.BlockPlayer{player = player.player, flip = not reverse}

		if #characters == 1 and not displayPlayerNames then
			local characterDisplay = mw.html.create('div'):addClass('brkts-popup-body-element-thumbs')
			local character = characters[1]
			if reverse then
				characterDisplay:wikitext(CharacterIcons[character]):wikitext('&nbsp;'):wikitext(character)
			else
				characterDisplay:wikitext(character):wikitext('&nbsp;'):wikitext(CharacterIcons[character])
			end
			playerWrapper:node(characterDisplay)
			return playerWrapper
		end

		local characterDisplays = Array.map(characters, function (character)
			local characterDisplay = mw.html.create('div'):addClass('brkts-popup-body-element-thumbs')
			characterDisplay:wikitext(CharacterIcons[character])
			return characterDisplay
		end)
		if displayPlayerNames then
			table.insert(characterDisplays, '&nbsp;')
			table.insert(characterDisplays, playerNode)
		end

		Array.forEach(characterDisplays, FnUtil.curry(playerWrapper.node, playerWrapper))
		return playerWrapper
	end)

	Array.forEach(playerDisplays, FnUtil.curry(wrapper.node, wrapper))

	return wrapper
end

return CustomMatchSummary

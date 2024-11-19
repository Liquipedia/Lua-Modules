---
-- @Liquipedia
-- wiki=smash
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local PlayerDisplay = require('Module:Player/Display')

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
---@param opponentIdx integer
---@return table[]
function CustomMatchSummary.fetchCharactersOfPlayers(game, matchOpponents, opponentIdx)
	return Array.map(game.opponents[opponentIdx].players, function (player, playerIndex)
		return Table.merge(matchOpponents[opponentIdx].players[playerIndex] or {}, player)
	end)
end

---@param game MatchGroupUtilGame
---@param props {soloMode: boolean, opponents: table[]}
---@return Widget?
function CustomMatchSummary._createStandardGame(game, props)
	if not game or not game.participants then
		return
	end

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '0.75rem', padding = '4px'},
		children = WidgetUtil.collect(
			CustomMatchSummary._createCharacterDisplay(
				CustomMatchSummary.fetchCharactersOfPlayers(game, props.opponents, 1),
				false,
				not props.soloMode
			),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{children = DisplayHelper.Map(game), css = {['flex-grow'] = '1'}},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			CustomMatchSummary._createCharacterDisplay(
				CustomMatchSummary.fetchCharactersOfPlayers(game, props.opponents, 2),
				true,
				not props.soloMode
			)
		)
	}
end

---@param players table[]
---@param reverse boolean?
---@param displayPlayerNames boolean?
---@return Html
function CustomMatchSummary._createCharacterDisplay(players, reverse, displayPlayerNames)
	local wrapper = mw.html.create('div'):css('flex-basis', '30%')

	if Logic.isDeepEmpty(players) then
		return wrapper
	end

	local playerDisplays = Array.map(players, function (player)
		local characters = player.characters
		if Logic.isEmpty(characters) then
			return
		end
		local playerWrapper = mw.html.create('div')
			:css('display', 'flex')
			:css('flex-direction', reverse and 'row' or 'row-reverse')

		local characterDisplays = Array.map(characters, function(character)
			local characterDisplay = mw.html.create('div'):addClass('brkts-popup-body-element-thumbs')
			characterDisplay:wikitext(CharacterIcon.Icon{character = character.name, size = '60px'})
			if not character.active then
				characterDisplay:css('opacity', '0.3')
			end
			return characterDisplay
		end)

		if displayPlayerNames then
			local playerNode = PlayerDisplay.BlockPlayer{player = player.player, flip = not reverse}
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

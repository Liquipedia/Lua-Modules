---
-- @Liquipedia
-- wiki=fighters
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local FnUtil = require('Module:FnUtil')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local ICONS = {
	winner = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = 'initial'},
	draw = Icon.makeIcon{iconName = 'draw', color = 'bright-sun-text', size = 'initial'},
	loss = Icon.makeIcon{iconName = 'loss', color = 'cinnabar-text', size = 'initial'},
	empty = '[[File:NoCheck.png|link=|16px]]',
}

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
	return '350px'
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local showCountdown = match.timestamp ~= DateExt.defaultTimestamp

	local games = Array.map(match.games, function(game)
		return CustomMatchSummary._createStandardGame(game, {
			opponents = match.opponents,
			game = match.game,
		})
	end)

	return MatchSummaryWidgets.Body{children = WidgetUtil.collect(
		showCountdown and MatchSummaryWidgets.Row{children = DisplayHelper.MatchCountdownBlock(match)} or nil,
		games
	)}
end

---@param game MatchGroupUtilGame
---@param teamIdx integer
---@return {name: string}[]
function CustomMatchSummary.fetchCharacters(game, teamIdx)
	local characters = {}
	for _, playerCharacters in Table.iter.pairsByPrefix(game.participants, teamIdx .. '_', {requireIndex = true}) do
		if playerCharacters.characters then
			table.insert(characters, playerCharacters.characters)
		end
	end
	return Array.flatten(characters)
end

---@param game MatchGroupUtilGame
---@param props {game: string?, opponents: standardOpponent[]}
---@return Html[]
function CustomMatchSummary._createStandardGame(game, props)
	local row = MatchSummary.Row()
		:addClass('brkts-popup-body-game')
		:css('font-size', '0.75rem')
		:css('padding', '4px')
		:css('min-height', '24px')

	game.extradata = game.extradata or {}

	local elements = {}

	if not game or not game.participants then
		return elements
	end

	local chars1 = CustomMatchSummary._createCharacterDisplay(
		CustomMatchSummary.fetchCharacters(game, 1),
		props.game,
		false
	)
	local chars2 = CustomMatchSummary._createCharacterDisplay(
		CustomMatchSummary.fetchCharacters(game, 2),
		props.game,
		true
	)

	row:addElement(chars1:css('flex-basis', '30%'))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner, 1))
	row:addElement(mw.html.create('div')
			:addClass('brkts-popup-spaced'):css('flex', '1 0 auto')
			:wikitext(game.scores[1]):wikitext('&nbsp;-&nbsp;'):wikitext(game.scores[2])
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner, 2))
	row:addElement(chars2:css('flex-basis', '30%'):css('text-align', 'right'))

	return elements
end

---@param characters {name: string}[]?
---@param game string?
---@param reverse boolean?
---@return Html
function CustomMatchSummary._createCharacterDisplay(characters, game, reverse)
	local CharacterIcons = mw.loadData('Module:CharacterIcons/' .. (game or ''))
	local wrapper = mw.html.create('div')

	if Table.isEmpty(characters) then
		return wrapper
	end
	---@cast characters -nil

	if #characters == 1 then
		local characterDisplay = mw.html.create('span'):addClass('draft faction')
		local character = characters[1]
		if reverse then
			characterDisplay:wikitext(character.name):wikitext('&nbsp;'):wikitext(CharacterIcons[character.name])
		else
			characterDisplay:wikitext(CharacterIcons[character.name]):wikitext('&nbsp;'):wikitext(character.name)
		end

		return characterDisplay
	end

	local characterDisplays = Array.map(characters, function (character, index)
		local characterDisplay = mw.html.create('span'):addClass('draft faction')
		characterDisplay:wikitext(CharacterIcons[character.name])
		return characterDisplay
	end)

	if reverse then
		characterDisplays = Array.reverse(characterDisplays)
	end

	Array.forEach(characterDisplays, FnUtil.curry(wrapper.node, wrapper))

	return wrapper
end

---@param winner integer|string
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._createCheckMark(winner, opponentIndex)
	return mw.html.create('div')
			:addClass('brkts-popup-spaced')
			:css('width', '16px')
			:css('line-height', '17px')
			:css('margin-left', (opponentIndex == 1) and '10%' or '1%')
			:css('margin-right', (opponentIndex == 2) and '10%' or '1%')
			:wikitext(
				winner == opponentIndex and ICONS.winner
				or winner == 0 and ICONS.draw
				or Logic.isNotEmpty(winner) and ICONS.loss
				or ICONS.empty
			)
end

return CustomMatchSummary

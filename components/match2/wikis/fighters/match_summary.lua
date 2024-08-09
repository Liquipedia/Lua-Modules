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
	local body = MatchSummary.Body()

	if match.dateIsExact or (match.timestamp ~= DateExt.defaultTimestamp) then
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	Array.forEach(CustomMatchSummary._displayGames(match), FnUtil.curry(body.addRow, body))

	return body
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryRow[]
function CustomMatchSummary._displayGames(match)
	return Array.map(match.games, function(game)
		local row = MatchSummary.Row()
				:addClass('brkts-popup-body-game')
				:css('font-size', '0.75rem')
				:css('padding', '4px')
				:css('min-height', '24px')

		local elements = CustomMatchSummary._createStandardGame(game, {
			opponents = match.opponents,
			game = match.game,
		})

		Array.forEach(elements, FnUtil.curry(row.addElement, row))

		return row
	end)
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	return footer
end

---@param game MatchGroupUtilGame
---@param teamIdx integer
---@return {name: string, active: boolean}[]
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

	table.insert(elements, chars1:css('flex', '1 1 35%'):css('text-align', 'right'))
	table.insert(elements, CustomMatchSummary._createCheckMark(game.winner, 1))
	table.insert(elements, mw.html.create('div')
			:addClass('brkts-popup-spaced')
			:wikitext(game.scores[1]):wikitext('&nbsp;-&nbsp;'):wikitext(game.scores[2])
	)
	table.insert(elements, CustomMatchSummary._createCheckMark(game.winner, 2))
	table.insert(elements, chars2:css('flex', '1 1 35%'))

	return elements
end

---@param characters {name: string, active: boolean}[]?
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
		if not character.active then
			characterDisplay:css('opacity', '0.3')
		end
		if reverse then
			characterDisplay:wikitext(CharacterIcons[character.name]):wikitext('&nbsp;'):wikitext(character.name)
		else
			characterDisplay:wikitext(character.name):wikitext('&nbsp;'):wikitext(CharacterIcons[character.name])
		end
		return characterDisplay
	end

	local characterDisplays = Array.map(characters, function (character, index)
		local characterDisplay = mw.html.create('span'):addClass('draft faction')
		if not character.active then
			characterDisplay:css('opacity', '0.3')
		end
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
			:css('margin-left', '2%')
			:css('margin-right', '2%')
			:wikitext(
				winner == opponentIndex and ICONS.winner
				or winner == 0 and ICONS.draw
				or Logic.isNotEmpty(winner) and ICONS.loss
				or ICONS.empty
			)
end

return CustomMatchSummary

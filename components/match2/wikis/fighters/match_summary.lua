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
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

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
---@param props {game: string?}
---@return Widget?
function CustomMatchSummary._createStandardGame(game, props)
	if not game or not game.participants then
		return
	end

	local scoreDisplay = (game.scores[1] or '') .. '&nbsp;-&nbsp;' .. (game.scores[2] or '')

	return MatchSummaryWidgets.Row{
		classes = {'brkts-popup-body-game'},
		css = {['font-size'] = '0.75rem', padding = '4px'},
		children = WidgetUtil.collect(
			CustomMatchSummary._createCharacterDisplay(
				CustomMatchSummary.fetchCharacters(game, 1),
				props.game,
				false
			),
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 1},
			MatchSummaryWidgets.GameCenter{children = scoreDisplay, css = {['flex-grow'] = 1}},
			MatchSummaryWidgets.GameWinLossIndicator{winner = game.winner, opponentIndex = 2},
			CustomMatchSummary._createCharacterDisplay(
				CustomMatchSummary.fetchCharacters(game, 2),
				props.game,
				true
			)
		)
	}
end

---@param characters {name: string}[]?
---@param game string?
---@param reverse boolean?
---@return Html
function CustomMatchSummary._createCharacterDisplay(characters, game, reverse)
	local CharacterIcons = mw.loadData('Module:CharacterIcons/' .. (game or ''))
	local wrapper = mw.html.create('div')
		:css('flex-basis', '30%')
		:css('text-align', reverse and 'right' or 'left')

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
		wrapper:node(characterDisplay)
		return wrapper
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

return CustomMatchSummary

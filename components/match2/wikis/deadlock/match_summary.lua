---
-- @Liquipedia
-- wiki=deadlock
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local FnUtil = require('Module:FnUtil')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local SIZE_HERO = '48x48px'
local ICONS = {
	winner = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = 'initial'},
	loss = Icon.makeIcon{iconName = 'loss', color = 'cinnabar-text', size = 'initial'},
	empty = '[[File:NoCheck.png|link=|16px]]',
}

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '400px', teamStyle = 'bracket'})
end

---@param match MatchGroupUtilMatch
---@return MatchSummaryBody
function CustomMatchSummary.createBody(match)
	local body = MatchSummary.Body()

	if match.dateIsExact or match.timestamp ~= DateExt.defaultTimestamp then
		body:addRow(MatchSummary.Row():addElement(
			DisplayHelper.MatchCountdownBlock(match)
		))
	end

	Array.forEach(Array.map(match.games, CustomMatchSummary._createGame), FnUtil.curry(body.addRow, body))

	return body
end

---@param participants table
---@param opponentIndex integer
---@return table
function CustomMatchSummary._getHeroesForOpponent(participants, opponentIndex)
	local characters = {}
	for _, participant in Table.iter.pairsByPrefix(participants, opponentIndex .. '_') do
		table.insert(characters, participant.character)
	end
	return characters
end

---@param game MatchGroupUtilGame
---@param gameIndex integer
---@return MatchSummaryRow
function CustomMatchSummary._createGame(game, gameIndex)
	local row = MatchSummary.Row()
	local extradata = game.extradata or {}

	row:addClass('brkts-popup-body-game')
		:css('font-size', '80%')
		:css('padding', '4px')

	local function makeCharacterDisplay(opponentIndex)
		return CustomMatchSummary._createCharacterDisplay(
			CustomMatchSummary._getHeroesForOpponent(game.participants, opponentIndex),
			extradata['team' .. opponentIndex .. 'side'],
			opponentIndex == 2
		)
	end

	row:addElement(makeCharacterDisplay(1))
	row:addElement(CustomMatchSummary._createCheckMark(game.winner, 1))
	row:addElement(mw.html.create('div')
		:addClass('brkts-popup-body-element-vertical-centered')
		:wikitext(Abbreviation.make(
			Logic.isEmpty(game.length) and ('Game ' .. gameIndex) or game.length,
			Logic.isEmpty(game.length) and ('Game ' .. gameIndex .. ' picks') or 'Match Length'
		))
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner, 2))
	row:addElement(makeCharacterDisplay(2))

	if Logic.isNotEmpty(game.comment) then
		row:addElement(MatchSummary.Break():create())
		row:addElement(mw.html.create('div'):css('margin', 'auto'):wikitext(game.comment))
	end

	return row
end

---@param winner integer|string
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._createCheckMark(winner, opponentIndex)
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '17px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')
		:wikitext(
			winner == opponentIndex and ICONS.winner
			or winner == 0 and ICONS.draw
			or Logic.isNotEmpty(winner) and ICONS.loss
			or ICONS.empty
		)
end

---@param characters {name: string, active: boolean}[]?
---@param side string?
---@param reverse boolean?
---@return Html
function CustomMatchSummary._createCharacterDisplay(characters, side, reverse)
	local wrapper = mw.html.create('div')
		:addClass('brkts-popup-body-element-thumbs')
		:addClass('brkts-popup-body-element-thumbs-' .. (reverse and 'right' or 'left'))
		:addClass('brkts-champion-icon')

	local function makeCharacterIcon(character)
		return CharacterIcon.Icon{
			character = character,
			size = SIZE_HERO,
		}
	end

	local function characterDisplay(character, showName)
		local display = mw.html.create('div')
		if not showName then
			display:node(makeCharacterIcon(character))
			return display
		end
		if reverse then
			display:wikitext(character):wikitext('&nbsp;'):wikitext(makeCharacterIcon(character))
		else
			display:node(makeCharacterIcon(character)):wikitext('&nbsp;'):wikitext(character)
		end
		return display
	end

	local characterDisplays = Array.map(characters or {}, function (character)
		return characterDisplay(character, #characters == 1)
	end)

	if reverse then
		characterDisplays = Array.reverse(characterDisplays)
	end

	Array.forEach(characterDisplays, FnUtil.curry(wrapper.node, wrapper))

	return wrapper
end

return CustomMatchSummary

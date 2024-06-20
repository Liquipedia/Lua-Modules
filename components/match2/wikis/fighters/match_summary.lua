---
-- @Liquipedia
-- wiki=fighters
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Lua = require('Module:Lua')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local GREEN_CHECK = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = 'initial'}
local DRAW_LINE = Icon.makeIcon{iconName = 'draw', color = 'bright-sun-text', size = 'initial'}
local NO_CHECK = '[[File:NoCheck.png|link=|16px]]'

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

	if not CustomMatchSummary._isSolo(match) then
		return body
	end

	Array.forEach(match.games, function(game)
		if not game.map and not game.winner then return end
		local row = MatchSummary.Row()
				:addClass('brkts-popup-body-game')
				:css('font-size', '0.75rem')
				:css('padding', '4px')
				:css('min-height', '24px')

		CustomMatchSummary._createGame(row, game, {
			opponents = match.opponents,
			game = match.game,
		})
		body:addRow(row)
	end)

	return body
end

---@param match MatchGroupUtilMatch
---@param footer MatchSummaryFooter
---@return MatchSummaryFooter
function CustomMatchSummary.addToFooter(match, footer)
	footer = MatchSummary.addVodsToFooter(match, footer)

	return footer
end

---@param match MatchGroupUtilMatch
---@return boolean
function CustomMatchSummary._isSolo(match)
	if type(match.opponents[1]) ~= 'table' or type(match.opponents[2]) ~= 'table' then
		return false
	end
	return match.opponents[1].type == Opponent.solo and match.opponents[2].type == Opponent.solo
end

---@param game MatchGroupUtilGame
---@param paricipantId string
---@return {displayName: string?, pageName: string?, flag: string?, characters: {name: string, active: boolean}[]?}
function CustomMatchSummary._getPlayerData(game, paricipantId)
	if not game or not game.participants then
		return {}
	end
	return game.participants[paricipantId] or {}
end

---@param row MatchSummaryRow
---@param game MatchGroupUtilGame
---@param props {game: string?, opponents: standardOpponent[]}
function CustomMatchSummary._createGame(row, game, props)
	game.extradata = game.extradata or {}

	local chars1 = CustomMatchSummary._createCharacterDisplay(
		CustomMatchSummary._getPlayerData(game, '1_1').characters,
		props.game
	)
	local chars2 = CustomMatchSummary._createCharacterDisplay(
		Array.reverse(CustomMatchSummary._getPlayerData(game, '2_1').characters),
		props.game
	)

	row:addElement(chars1)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner, 1))
	row:addElement(mw.html.create('div')
			:addClass('brkts-popup-spaced'):css('flex-grow', '1')
			:wikitext(game.scores[1]):wikitext('&nbsp;-&nbsp;'):wikitext(game.scores[2])
	)
	row:addElement(CustomMatchSummary._createCheckMark(game.winner, 2))
	row:addElement(chars2)
end

---@param characters {name: string, active: boolean}[]?
---@param game string?
---@return Html
function CustomMatchSummary._createCharacterDisplay(characters, game)
	local CharacterIcons = mw.loadData('Module:CharacterIcons/' .. (game or ''))

	local wrapper = mw.html.create('div')
	Array.forEach(characters or {}, function (character, index)
		local characterDisplay = mw.html.create('span'):addClass('draft faction')
		if not character.active then
			characterDisplay:css('opacity', '0.3')
		end
		characterDisplay:wikitext(CharacterIcons[character.name]):wikitext('&nbsp;'):wikitext(character.name)
		wrapper:node(characterDisplay)
	end)

	return wrapper
end

---@param winner integer|string
---@param opponentIndex integer
---@return Html
function CustomMatchSummary._createCheckMark(winner, opponentIndex)
	return mw.html.create('div')
			:addClass('brkts-popup-spaced')
			:css('line-height', '17px')
			:css('margin-left', (opponentIndex == 1) and '10%' or '1%')
			:css('margin-right', (opponentIndex == 2) and '10%' or '1%')
			:wikitext(
				winner == opponentIndex and GREEN_CHECK
				or winner == 0 and DRAW_LINE or NO_CHECK
			)
end

return CustomMatchSummary

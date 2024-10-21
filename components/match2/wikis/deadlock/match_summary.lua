---
-- @Liquipedia
-- wiki=deadlock
-- page=Module:MatchSummary
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local FnUtil = require('Module:FnUtil')
local DateExt = require('Module:Date/Ext')
local Icon = require('Module:Icon')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local DisplayHelper = Lua.import('Module:MatchGroup/Display/Helper')
local MatchSummary = Lua.import('Module:MatchSummary/Base')
local MatchSummaryWidgets = Lua.import('Module:Widget/Match/Summary/All')

local MAX_NUM_BANS = 6
local ICONS = {
	winner = Icon.makeIcon{iconName = 'winner', color = 'forest-green-text', size = 'initial'},
	loss = Icon.makeIcon{iconName = 'loss', color = 'cinnabar-text', size = 'initial'},
	amber = Icon.makeIcon{iconName = 'amberhand', color = 'deadlock-amberhand-text', size = 'initial'},
	sapphire = Icon.makeIcon{iconName = 'sapphireflame', color = 'deadlock-sapphireflame-text', size = 'initial'},
	empty = '[[File:NoCheck.png|link=|16px]]',
}

local CustomMatchSummary = {}

---@param args table
---@return Html
function CustomMatchSummary.getByMatchId(args)
	return MatchSummary.defaultGetByMatchId(CustomMatchSummary, args, {width = '440px', teamStyle = 'bracket'})
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

	-- Iterate each map
	Array.forEach(Array.map(match.games, CustomMatchSummary._createGame), FnUtil.curry(body.addRow, body))

	-- Add the Hero Bans
	local characterBansData = MatchSummary.buildCharacterBanData(match.games, MAX_NUM_BANS)
	body.root:node(MatchSummaryWidgets.CharacterBanTable{
		bans = characterBansData,
		date = match.date,
	})

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
		return MatchSummaryWidgets.Characters{
			characters = CustomMatchSummary._getHeroesForOpponent(game.participants, opponentIndex),
			flipped = opponentIndex == 2,
		}
	end

	row:addElement(CustomMatchSummary._createIcon(ICONS[extradata.team1side]))
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
	row:addElement(CustomMatchSummary._createIcon(ICONS[extradata.team2side]))

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
	return CustomMatchSummary._createIcon(
			winner == opponentIndex and ICONS.winner
			or winner == 0 and ICONS.draw
			or Logic.isNotEmpty(winner) and ICONS.loss
			or ICONS.empty
		)
end

---@param icon string
---@return Html
function CustomMatchSummary._createIcon(icon)
	return mw.html.create('div')
		:addClass('brkts-popup-spaced')
		:css('line-height', '17px')
		:css('margin-left', '1%')
		:css('margin-right', '1%')
		:wikitext(icon)
end

return CustomMatchSummary

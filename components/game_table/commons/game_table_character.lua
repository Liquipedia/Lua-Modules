---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:GameTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local GameTable = Lua.import('Module:GameTable')

local CustomGameTable = Class.new(GameTable)

---@param frame Frame
---@return Html
function CustomGameTable.results(frame)
	local args = Arguments.getArgs(frame)

	return CustomGameTable(args):readConfig():query():build()
end

---@return Html
function CustomGameTable:headerRow()
	local makeHeaderCell = function(text, width)
		return mw.html.create('th'):css('max-width', width):node(text)
	end

	return mw.html.create('tr')
		:node(makeHeaderCell('Date', '100px'))
		:node(makeHeaderCell('Tier', '70px') or nil)
		:node(makeHeaderCell(nil, '25px'):addClass('unsortable'))
		:node(makeHeaderCell('Tournament'))
		:node(makeHeaderCell('vs.', '80px'))
		:node(makeHeaderCell('Picks'):addClass('unsortable'))
		:node(makeHeaderCell('Bans'):addClass('unsortable'))
		:node(makeHeaderCell('vs. Picks'):addClass('unsortable'))
		:node(makeHeaderCell('vs. Bans'):addClass('unsortable'))
		:node(makeHeaderCell('Length'))
		:node(makeHeaderCell('VOD', '60px') or nil)
end

---@param game match2game
---@param prefix string
---@return Html?
function CustomGameTable:_displayCharacters(game, prefix)
	local characters = mw.html.create('td')
	for _, character in Table.iter.pairsByPrefix(game.extradata, prefix) do
		characters:node(CharacterIcon.Icon{character = character, size = '27px', date = game.date})
	end

	return characters
end

---@param game match2game
---@param opponentIndex number
---@return Html?
function CustomGameTable:_displayDraft(game, opponentIndex)
	if Table.isEmpty(game.extradata) then
		return nil
	end

	local side = game.extradata['team' .. opponentIndex .. 'side']
	local sideClass = Logic.isNotEmpty(side) and 'brkts-popup-side-color-' .. side or nil
	return mw.html.create()
		:node(self:_displayCharacters(game, 'team' .. opponentIndex .. 'champion')
			:addClass(sideClass)
		)
		:node(self:_displayCharacters(game, 'team' .. opponentIndex .. 'ban')
			:addClass(sideClass)
			:addClass('lor-graycard')
		)
end

---@param match GameTableMatch
---@param game match2game
---@return Html?
function CustomGameTable:_displayGame(match, game)
	return mw.html.create()
		:node(self:_displayOpponent(match.result.vs):css('text-align', 'left'))
		:node(self:_displayDraft(game, match.result.opponent.id))
		:node(self:_displayDraft(game, match.result.vs.id))
end

---@param game match2game
---@return Html?
function CustomGameTable:_displayLength(game)
	return mw.html.create('td')
		:node(game.length)
end

---@param match GameTableMatch
---@param game match2game
---@return Html?
function CustomGameTable:gameRow(match, game)
	local winner = match.result.opponent.id == tonumber(game.winner) and 1 or 2

	return mw.html.create('tr')
		:addClass(self:_getBackgroundClass(winner))
		:node(self:_displayDate(match))
		:node(self:_displayTier(match))
		:node(self:_displayIcon(match))
		:node(self:_displayTournament(match))
		:node(self:_displayGame(match, game))
		:node(self:_displayLength(game))
		:node(self:_displayGameVod(game.vod))
end

return CustomGameTable

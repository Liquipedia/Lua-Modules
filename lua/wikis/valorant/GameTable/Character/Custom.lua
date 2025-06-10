---
-- @Liquipedia
-- page=Module:GameTable/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MathUtil = require('Module:MathUtil')
local Page = require('Module:Page')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

local CharacterGameTable = Lua.import('Module:GameTable/Character')

---@class ValorantCharacterGameTable: CharacterGameTable
local CustomCharacterGameTable = Class.new(CharacterGameTable, function (self)
	self.args.showBans = false

	if self.args.tableMode == Opponent.solo then
		self.isPickedByRequired = true
		self.args.showOnlyGameStats = true
		self.statsFromMatches = CharacterGameTable.statsFromMatches
	end
end)

---@param game CharacterGameTableGame
---@return number?
function CustomCharacterGameTable:getCharacterPick(game)
	if self.config.mode ~= Opponent.solo then
		return CharacterGameTable.getCharacterPick(self, game)
	end
	local aliases = self.config.aliases
	local found

	Array.forEach(game.opponents, function(opponent, opponentIndex)
		if found then return end
		Array.forEach(opponent.players, function(player, playerIndex)
			if found then return end
			if aliases[player.player] then
				game.pickedByplayer = playerIndex
				found = opponentIndex
				return
			end
		end)
	end)

	return found
end

---@return integer
function CustomCharacterGameTable:getNumberOfPicks()
	return 10
end

---@param opponentIndex number
---@param playerIndex number
---@return string
function CustomCharacterGameTable:getCharacterKey(opponentIndex, playerIndex)
	return 't' .. opponentIndex .. 'p' .. playerIndex .. 'agent'
end

---@return Html
function CustomCharacterGameTable:headerRow()
	local makeHeaderCell = function(text, width)
		return mw.html.create('th'):css('max-width', width):node(text)
	end

	local config = self.config

	local nodes = Array.append({},
		makeHeaderCell('Date', '100px'),
		config.showTier and makeHeaderCell('Tier', '70px') or nil,
		config.showType and makeHeaderCell('Type', '70px') or nil,
		config.showIcon and makeHeaderCell(nil, '25px'):addClass('unsortable') or nil,
		makeHeaderCell('Tournament'),
		makeHeaderCell('Map'),
		(config.showResult and config.mode == Opponent.solo) and makeHeaderCell('') or nil,
		(config.showResult and config.mode ~= Opponent.team) and makeHeaderCell('K') or nil,
		(config.showResult and config.mode ~= Opponent.team) and makeHeaderCell('D') or nil,
		(config.showResult and config.mode ~= Opponent.team) and makeHeaderCell('A') or nil,
		(config.showResult and config.mode ~= Opponent.team) and makeHeaderCell('Ratio') or nil,
		config.showResult and makeHeaderCell('Picks'):addClass('unsortable') or nil,
		config.showResult and makeHeaderCell(nil, '80px') or nil,
		config.showResult and makeHeaderCell('Score') or nil,
		config.showResult and makeHeaderCell(nil, '80px') or nil,
		config.showResult and makeHeaderCell('vs. Picks'):addClass('unsortable') or nil,
		config.showLength and makeHeaderCell('Length') or nil,
		config.showVod and makeHeaderCell('VOD', '60px') or nil
	)

	local header = mw.html.create('tr')
	Array.forEach(nodes, function (node)
		header:node(node)
	end)

	return header
end

---@param participant table
---@return number?
function CustomCharacterGameTable:_getRatio(participant)
	local kills = tonumber(participant.kills) or 0
	local deaths = tonumber(participant.deaths) or 0
	if deaths == 0 then
		return nil
	end

	return MathUtil.round(kills / deaths, 1)
end

---@param match GameTableMatch
---@param game CharacterGameTableGame
---@return Html?
function CustomCharacterGameTable:displayGame(match, game)
	local makeCell = function (text)
		return mw.html.create('td'):node(text)
	end

	local makeIcon = function (character)
		if not character then return nil end
		return mw.html.create('td')
			:node(CharacterIcon.Icon{character = character, size = self.config.iconSize, date = game.date})
	end

	local opponent = match.result.opponent
	local opponentVs = match.result.vs
	if self.isCharacterTable then
		local pickedBy = game.pickedBy
		---@cast pickedBy -nil
		if pickedBy == 2 then
			opponent, opponentVs = opponentVs, opponent
		end
	end

	local node = mw.html.create()
		:node(makeCell(Page.makeInternalLink(game.map)))

	if self.config.mode ~= Opponent.team then
		local participant = game.opponents[game.pickedBy].players[game.pickedByplayer]
		if self.config.mode == Opponent.solo then
			local index = Array.indexOf(game.picks[game.pickedBy], function (pick)
				return participant.agent == pick
			end)
			node:node(index > 0 and makeIcon(table.remove(game.picks[game.pickedBy], index)) or makeCell())
		end
		node
			:node(makeCell(participant and participant.kills or nil))
			:node(makeCell(participant and participant.deaths or nil))
			:node(makeCell(participant and participant.assists or nil))
			:node(makeCell(participant and self:_getRatio(participant) or nil))
	end

	return node
		:node(self:_displayCharacters(game, opponent.id, 'picks'))
		:node(self:_displayOpponent(opponent, false))
		:node(self:_displayScore(game, opponent.id, opponentVs.id))
		:node(self:_displayOpponent(opponentVs, true))
		:node(self:_displayCharacters(game, opponentVs.id, 'picks'))
end

---@param frame Frame
---@return Html
function CustomCharacterGameTable.results(frame)
	local args = Arguments.getArgs(frame)

	return CustomCharacterGameTable(args):readConfig():query():build()
end

return CustomCharacterGameTable

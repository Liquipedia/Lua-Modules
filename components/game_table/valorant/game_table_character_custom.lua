---
-- @Liquipedia
-- wiki=valorant
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
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent

---@class ValorantCustomGameTableCharacter: CharacterGameTable
local CharacterGameTable = Lua.import('Module:GameTable/Character')

---@class CustomGameTableCharacter: CharacterGameTable
local CustomGameTableCharacter = Class.new(CharacterGameTable, function (self)
	self.args.showBans = false

	if self.args.tableMode == Opponent.solo then
		self.isPickedByRequired = true
		self.args.showOnlyGameStats = true
		self.statsFromMatches = CharacterGameTable.statsFromMatches
	end
end)

---@param game CharacterGameTableGame
---@return number?
function CustomGameTableCharacter:getCharacterPick(game)
	if self.config.mode ~= Opponent.solo then
		return CharacterGameTable.getCharacterPick(self, game)
	end
	local aliases = self.config.aliases
	local found
	Table.iter.forEachPair(game.participants, function (participantId, participant)
		if found then return end
		found = aliases[participant.player] and participantId or nil
		if found then
			local pKey = Array.parseCommaSeparatedString(participantId, '_')
			game.pickedByplayer = tonumber(pKey[2])
			found = tonumber(pKey[1])
			return
		end
	end)

	return found
end

---@return integer
function CustomGameTableCharacter:getNumberOfPicks()
	return 10
end

---@param opponentIndex number
---@param playerIndex number
---@return string
function CustomGameTableCharacter:getCharacterKey(opponentIndex, playerIndex)
	return 't' .. opponentIndex .. 'p' .. playerIndex .. 'agent'
end

---@return Html
function CustomGameTableCharacter:headerRow()
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
function CustomGameTableCharacter:_getRatio(participant)
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
function CustomGameTableCharacter:_displayGame(match, game)
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
		opponent = pickedBy == 1 and match.result.opponent or match.result.vs
		opponentVs = pickedBy == 2 and match.result.opponent or match.result.vs
	end

	local node = mw.html.create()
		:node(makeCell(Page.makeInternalLink(game.map)))

	if self.config.mode ~= Opponent.team then
		local participant = game.participants[game.pickedBy .. '_' .. game.pickedByplayer]
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
function CustomGameTableCharacter.results(frame)
	local args = Arguments.getArgs(frame)

	return CustomGameTableCharacter(args):readConfig():query():build()
end

return CustomGameTableCharacter

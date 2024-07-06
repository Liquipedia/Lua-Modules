---
-- @Liquipedia
-- wiki=commons
-- page=Module:GameTable/Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local GameTable = Lua.import('Module:GameTable')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local DRAW = 'draw'
local CHARACTER_MODE = 'character'
local SCORE_CONCAT = '&nbsp;&#58;&nbsp;'

---@class CharacterGameTableConfig: MatchTableConfig
---@field showGameWithoutCharacters boolean
---@field showBans boolean
---@field numPicks number
---@field numBans number

---@class CharacterGameTableGame: match2game
---@field picks string[][]
---@field bans string[][]?
---@field pickedBy number?

---@class CharacterGameTable: GameTable
---@field isCharacterTable boolean
---@field iconSize string
---@field config CharacterGameTableConfig
local CharacterGameTable = Class.new(GameTable, function (self)
	self.isCharacterTable = self.args.tableMode == CHARACTER_MODE
	self.iconSize = self.args.iconSize or '27px'

	if not self.isCharacterTable then
		self.resultFromRecord = GameTable.resultFromRecord
		self.buildConditions = GameTable.buildConditions
		self.statsFromMatches = GameTable.statsFromMatches
	end
end)

---@return integer
function CharacterGameTable:getNumberOfPicks()
	return 5
end

---@return integer
function CharacterGameTable:getNumberOfBans()
	return 5
end

function CharacterGameTable:readConfig()
	local args = self.args

	if self.isCharacterTable then
		self.args.showOnlyGameStats = true
		self.config = self:_readDefaultConfig()
	else
		GameTable.readConfig(self)
	end
	self.config = Table.merge(self.config, {
		showGameWithoutCharacters = Logic.readBool(args.showGameWithoutCharacters),
		showBans = Logic.nilOr(Logic.readBoolOrNil(args.showBans), true),
		numPicks = self:getNumberOfPicks(),
		numBans = self:getNumberOfBans(),
	})

	return self
end

---@param opponentIndex number
---@param playerIndex number
---@return string
function CharacterGameTable:getCharacterKey(opponentIndex, playerIndex)
	return 'team' .. opponentIndex .. 'champion' .. playerIndex
end

---@param opponentIndex number
---@param playerIndex number
---@return string
function CharacterGameTable:getCharacterBanKey(opponentIndex, playerIndex)
	return 'team' .. opponentIndex .. 'ban' .. playerIndex
end

---@param extradata table
---@param opponentIndex number
---@return string?
function CharacterGameTable:getSideClass(extradata, opponentIndex)
	local side = extradata['team' .. opponentIndex .. 'side']
	return Logic.isNotEmpty(side) and 'brkts-popup-side-color-' .. side or nil
end

---@return string
function CharacterGameTable:_buildMatchConditions()
	return ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('winner'), Comparator.notEquals, '')}
		:add{ConditionNode(ColumnName('mode'), Comparator.equals, 'team')}
		:add{self:_buildCharacterConditions()}
		:add{self:buildDateConditions()}
		:toString()
end

---@return ConditionTree
function CharacterGameTable:_buildCharacterConditions()
	local character = self.args.character
	local characterConditions = ConditionTree(BooleanOperator.any)

	---@param opponentIndex number
	local addCondtions = function (opponentIndex)
		Array.forEach(Array.range(1, self.config.numPicks), function (index)
			characterConditions:add(ConditionNode(
			ColumnName(self:getCharacterKey(opponentIndex, index), 'extradata'),
			Comparator.eq,
			character
		))
		end)
	end

	addCondtions(1)
	addCondtions(2)

	return characterConditions
end

---@return string
function CharacterGameTable:buildConditions()
	local lpdbData = mw.ext.LiquipediaDB.lpdb('match2game', {
		conditions = self:_buildMatchConditions(),
		query = 'match2id',
		order = 'date desc',
		groupby = 'match2id asc',
		limit = self.config.limit
	})

	local conditions = ConditionTree(BooleanOperator.any)
	Array.forEach(lpdbData, function (game)
		conditions:add(ConditionNode(ColumnName('match2id'), Comparator.eq, game.match2id))
	end)

	return conditions:toString()
end

---@param game CharacterGameTableGame
---@param maxNumber number
---@param keyMaker fun(self, opponentIndex, playerIndex)
function CharacterGameTable:getCharacters(game, maxNumber, keyMaker)
	---@param opponentIndex number
	---@return table
	local getOpponentCharacters = function (opponentIndex)
		local characters = {}
		Array.forEach(Array.range(1, maxNumber), function (characterIndex)
			table.insert(characters, game.extradata[keyMaker(self, opponentIndex, characterIndex)])
		end)
		return characters
	end

	return {getOpponentCharacters(1), getOpponentCharacters(2)}
end


---@param picks string[][]
---@return number?
function CharacterGameTable:_getCharacterPick(picks)
	---@param opponentIndex number
	---@return number?
	local findCharacter = function (opponentIndex)
		local found = Array.find(picks[opponentIndex], function (character)
			return character == self.args.character
		end)

		return found and opponentIndex or nil
	end
	return findCharacter(1) or findCharacter(2)
end

---@param game match2game
---@return match2game?
function CharacterGameTable:gameFromRecord(game)
	local gameRecord = GameTable.gameFromRecord(self, game)
	if not gameRecord then
		return nil
	end

	---@cast gameRecord CharacterGameTableGame
	gameRecord.picks = self:getCharacters(gameRecord, self.config.numPicks, self.getCharacterKey)
	gameRecord.bans = self.config.showBans and self:getCharacters(gameRecord, self.config.numBans, self.getCharacterBanKey) or nil
	gameRecord.pickedBy = self.isCharacterTable and self:_getCharacterPick(gameRecord.picks) or nil

	local foundPicks = Table.isEmpty(gameRecord.picks[1]) and Table.isEmpty(gameRecord.picks[2])
	foundPicks = not self.isCharacterTable and foundPicks or Logic.isNotEmpty(gameRecord.pickedBy)

	return (self.config.showGameWithoutCharacters or foundPicks) and gameRecord or nil
end

---@param record table
---@return MatchTableMatchResult?
function CharacterGameTable:resultFromRecord(record)
	return {
		opponent = record.match2opponents[1],
		vs = record.match2opponents[2],
		winner = tonumber(record.winner),
		resultType = record.resultType,
		countGames = true,
	}
end

---@return {games: {w: number, d: number, l: number}}
function CharacterGameTable:statsFromMatches()
	local totalGames = {w = 0, d = 0, l = 0}

	Array.forEach(self.matches, function(match)
		---@cast match GameTableMatch
		Array.forEach(match.games, function (game, index)
			local winner = tonumber(game.winner)

			if game.resulttype == DRAW then
				totalGames.d = totalGames.d + 1
			elseif game.pickedBy == winner then
				totalGames.w = totalGames.w + 1
			else
				totalGames.l = totalGames.l + 1
			end
		end)
	end)

	return {
		games = totalGames,
	}
end

---@return Html
function CharacterGameTable:headerRow()
	local makeHeaderCell = function(text, width)
		return mw.html.create('th'):css('max-width', width):node(text)
	end

	local nodes = Array.append({},
		makeHeaderCell('Date', '100px'),
		makeHeaderCell(self.config.showTier and 'Tier', '70px') or nil,
		makeHeaderCell(nil, '25px'):addClass('unsortable'),
		makeHeaderCell('Tournament')
	)
	if self.isCharacterTable then
		nodes = Array.append(nodes,
			makeHeaderCell('Team'):addClass('unsortable'),
			makeHeaderCell(nil, '80px'),
			makeHeaderCell('Score'),
			makeHeaderCell(nil, '80px'),
			makeHeaderCell('vs. Team'):addClass('unsortable')
		)
	else
		nodes = Array.append(nodes,
			makeHeaderCell('vs.', '80px'),
			makeHeaderCell('Picks'):addClass('unsortable'),
			self.config.showBans and makeHeaderCell('Bans'):addClass('unsortable') or nil,
			makeHeaderCell('vs. Picks'):addClass('unsortable'),
			self.config.showBans and makeHeaderCell('vs. Bans'):addClass('unsortable') or nil
		)
	end

	nodes = Array.append(nodes,
		makeHeaderCell('Length'),
		self.config.showVod and makeHeaderCell('VOD', '60px') or nil
	)

	local header = mw.html.create('tr')
	Array.forEach(nodes, function (node)
		header:node(node)
	end)

	return header
end

---@param game CharacterGameTableGame
---@param opponentIndex number
---@param key string
---@return Html?
function CharacterGameTable:_displayCharacters(game, opponentIndex, key)
	local charactersDiv = mw.html.create('div')
		:addClass(self:getSideClass(game.extradata, opponentIndex))
		:css('display', 'flex')

	local makeIcon = function(character)
		return CharacterIcon.Icon{character = character, size = self.iconSize, date = game.date}
	end

	local icons = Array.map(game[key][opponentIndex] or {}, makeIcon)

	return mw.html.create('td')
		:node(#icons > 0 and charactersDiv:node(table.concat(icons, '')) or nil)
end

---@param match GameTableMatch
---@param game CharacterGameTableGame
---@return Html?
function CharacterGameTable:_displayGame(match, game)
	if self.isCharacterTable then
		local pickedBy = game.pickedBy
		---@cast pickedBy -nil
		local pickedVs = pickedBy == 1 and 2 or 1
		local opponentRecords = {match.result.opponent, match.result.vs}
		return mw.html.create()
			:node(self:_displayDraft(game, opponentRecords[pickedBy], false))
			:node(self:_displayScore(game, pickedBy, pickedVs))
			:node(self:_displayDraft(game, opponentRecords[pickedVs], true))

	else
		return mw.html.create()
			:node(self:_displayOpponent(match.result.vs):css('text-align', 'left'))
			:node(self:_displayDraft(game, match.result.opponent))
			:node(self:_displayDraft(game, match.result.vs))
	end
end

---@param game CharacterGameTableGame
---@param opponentRecord match2opponent
---@param flipped boolean?
---@return Html?
function CharacterGameTable:_displayDraft(game, opponentRecord, flipped)
	local opponentIndex = opponentRecord.id
	local characters = self:_displayCharacters(game, opponentIndex, 'picks')

	local draft = mw.html.create()
	if self.isCharacterTable then
		local opponent = self:_displayOpponent(opponentRecord, flipped)
		draft
			:node(flipped and opponent or characters)
			:node(flipped and characters or opponent)
	else
		draft
			:node(characters)
			:node(self:_displayCharacters(game, opponentIndex, 'bans')
				:addClass('lor-graycard')
			)
		end

	return draft
end

---@param game match2game
---@param pickedBy number
---@param pickedVs number
---@return Html
function CharacterGameTable:_displayScore(game, pickedBy, pickedVs)
	local winner = tonumber(game.winner)

	local toScore = function(opponentId)
		local isWinner = winner == opponentId
		return mw.html.create(isWinner and 'b' or nil)
			:wikitext(isWinner and 'W' or 'L')
	end

	return mw.html.create('td')
		:addClass('match-table-score')
		:node(toScore(pickedBy))
		:node(SCORE_CONCAT)
		:node(toScore(pickedVs))
end

---@param game match2game
---@return Html?
function CharacterGameTable:_displayLength(game)
	return mw.html.create('td')
		:node(game.length)
end

---@param match GameTableMatch
---@param game CharacterGameTableGame
---@return Html?
function CharacterGameTable:gameRow(match, game)
	local winner = (self.isCharacterTable and game.pickedBy or
		match.result.opponent.id) == tonumber(game.winner) and 1 or 2

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

---@param frame Frame
---@return Html
function CharacterGameTable.results(frame)
	local args = Arguments.getArgs(frame)

	return CharacterGameTable(args):readConfig():query():build()
end

return CharacterGameTable

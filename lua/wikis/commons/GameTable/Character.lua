---
-- @Liquipedia
-- page=Module:GameTable/Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local GameTable = Lua.import('Module:GameTable')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local DRAW_WINNER = 0
local CHARACTER_MODE = 'character'
local SCORE_CONCAT = '&nbsp;&#58;&nbsp;'

---@class CharacterGameTableConfig: MatchTableConfig
---@field showGameWithoutCharacters boolean
---@field showSideClass boolean
---@field showBans boolean
---@field showLength boolean
---@field numPicks number
---@field numBans number
---@field iconSize string
---@field iconSeparator string

---@class CharacterGameTableGame: match2game
---@field picks string[][]
---@field bans string[][]?
---@field pickedBy number?
---@field pickedByplayer number?

---@class CharacterGameTable: GameTable
---@field character string
---@field isCharacterTable boolean
---@field isPickedByRequired boolean
---@field config CharacterGameTableConfig
local CharacterGameTable = Class.new(GameTable, function (self)
	self.isCharacterTable = self.args.tableMode == CHARACTER_MODE
	self.isPickedByRequired = self.isCharacterTable

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

---@return self
function CharacterGameTable:readCharacter()
	if Logic.isNotEmpty(self.args.character) then
		self.character = self.args.character
	else
		assert(self.title.namespace == 0, 'Lua.importd character= argument')
		self.character = self.title.rootText
	end

	return self
end

---@return self
function CharacterGameTable:readConfig()
	local args = self.args

	if self.isCharacterTable then
		self.args.showOnlyGameStats = true
		self.config = self:_readDefaultConfig()
		self:readCharacter()
	else
		GameTable.readConfig(self)
	end
	self.config = Table.merge(self.config, {
		showGameWithoutCharacters = Logic.readBool(args.showGameWithoutCharacters),
		showSideClass = Logic.nilOr(Logic.readBoolOrNil(args.showSideClass), true),
		showBans = Logic.nilOr(Logic.readBoolOrNil(args.showBans), true),
		showLength = Logic.readBool(args.length),
		numPicks = self:getNumberOfPicks(),
		numBans = self:getNumberOfBans(),
		iconSize = Logic.nilIfEmpty(self.args.iconSize) or '27px',
		iconSeparator = Logic.nilIfEmpty(args.iconSeparator) or ''
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
	local character = self.character
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
---@return table[]
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


---@param game CharacterGameTableGame
---@return number?
function CharacterGameTable:getCharacterPick(game)
	---@param opponentIndex number
	---@return number?
	local findCharacter = function (opponentIndex)
		local found = Array.indexOf(game.picks[opponentIndex], function (character)
			return character == self.character
		end)
		game.pickedByplayer = found > 0 and found or nil

		return found > 0 and opponentIndex or nil
	end

	local winner = tonumber(game.winner)
	if winner ~= 0 then
		return findCharacter(winner) or findCharacter(winner == 1 and 2 or 1)
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
	gameRecord.bans = self.config.showBans and
		self:getCharacters(gameRecord, self.config.numBans,self.getCharacterBanKey) or nil
	gameRecord.pickedBy = self.isPickedByRequired and self:getCharacterPick(gameRecord) or nil

	if self.isPickedByRequired then
		return Logic.isNotEmpty(gameRecord.pickedBy) and gameRecord or nil
	end

	local foundPicks = Table.isNotEmpty(gameRecord.picks[1]) or Table.isNotEmpty(gameRecord.picks[2])
	return (foundPicks or self.config.showGameWithoutCharacters) and gameRecord or nil
end

---@param record table
---@return MatchTableMatchResult?
function CharacterGameTable:resultFromRecord(record)
	return {
		opponent = record.match2opponents[1],
		vs = record.match2opponents[2],
		winner = tonumber(record.winner),
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

			if game.winner == DRAW_WINNER then
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

	local config = self.config

	local nodes = Array.append({},
		makeHeaderCell('Date', '100px'),
		config.showTier and makeHeaderCell('Tier', '70px') or nil,
		config.showType and makeHeaderCell('Type', '70px') or nil,
		config.displayGameIcons and makeHeaderCell(nil, '25px') or nil,
		config.showIcon and makeHeaderCell(nil, '25px'):addClass('unsortable') or nil,
		makeHeaderCell('Tournament')
	)

	if config.showResult then
		local isCharTable = self.isCharacterTable
		nodes = Array.appendWith(nodes,
			not isCharTable and makeHeaderCell('vs.', '80px') or nil,
			makeHeaderCell('Picks'):addClass('unsortable'),
			config.showBans and makeHeaderCell('Bans'):addClass('unsortable') or nil,
			isCharTable and makeHeaderCell(nil, '80px') or nil,
			isCharTable and makeHeaderCell('Score') or nil,
			isCharTable and makeHeaderCell(nil, '80px') or nil,
			makeHeaderCell('vs. Picks'):addClass('unsortable'),
			config.showBans and makeHeaderCell('vs. Bans'):addClass('unsortable') or nil
		)
	end

	nodes = Array.append(nodes,
		config.showLength and makeHeaderCell('Length') or nil,
		config.showVod and makeHeaderCell('VOD', '60px') or nil
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
	local config = self.config
	local makeIcon = function(character)
		return CharacterIcon.Icon{character = character, size = config.iconSize, date = game.date}
	end

	local icons = Array.map(game[key][opponentIndex] or {}, makeIcon)

	return mw.html.create('td')
		:addClass(config.showSideClass and self:getSideClass(game.extradata, opponentIndex) or nil)
		:node(#icons > 0 and table.concat(icons, config.iconSeparator) or nil)
end

---@param match GameTableMatch
---@param game CharacterGameTableGame
---@return Html?
function CharacterGameTable:displayGame(match, game)
	if not self.config.showResult then
		return
	end

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

	local isCharTable = self.isCharacterTable
	local opponent = self:_displayOpponent(opponentRecord, flipped)
	return mw.html.create()
		:node((flipped and isCharTable) and opponent or nil)
		:node(self:_displayCharacters(game, opponentIndex, 'picks'))
		:node(self.config.showBans and
			self:_displayCharacters(game, opponentIndex, 'bans'):addClass('lor-graycard') or nil
		)
		:node((not flipped and isCharTable) and opponent or nil)
end

---@param game CharacterGameTableGame
---@param pickedBy number
---@param pickedVs number
---@return Html
function CharacterGameTable:_displayScore(game, pickedBy, pickedVs)
	local winner = tonumber(game.winner)
	local scores = Array.map(game.opponents, Operator.property('score'))

	local toScore = function(opponentId)
		local isWinner = winner == opponentId
		return mw.html.create(isWinner and 'b' or nil)
			:wikitext(scores[opponentId] or (isWinner and 'W' or 'L'))
	end

	return mw.html.create('td')
		:addClass('match-table-score')
		:node(toScore(pickedBy))
		:node(SCORE_CONCAT)
		:node(toScore(pickedVs))
end

---@param game CharacterGameTableGame
---@return Html?
function CharacterGameTable:_displayLength(game)
	if not self.config.showLength then return end

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
		:node(self:_displayType(match))
		:node(self:_displayGameIconForGame(game))
		:node(self:_displayIcon(match))
		:node(self:_displayTournament(match))
		:node(self:displayGame(match, game))
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

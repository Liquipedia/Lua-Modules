---
-- @Liquipedia
-- page=Module:GameTable/Character
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local Operator = Lua.import('Module:Operator')
local Table = Lua.import('Module:Table')

local GameTable = Lua.import('Module:GameTable')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local MatchSummaryCharacters = Lua.import('Module:Widget/Match/Summary/Characters')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DRAW_WINNER = 0
local CHARACTER_MODE = 'character'
local SCORE_CONCAT = '&nbsp;&colon;&nbsp;'

---@class CharacterGameTableConfig: MatchTableConfig
---@field showGameWithoutCharacters boolean
---@field showSideClass boolean
---@field showBans boolean
---@field showLength boolean
---@field numPicks number
---@field numBans number
---@field iconSize string
---@field iconSeparator string

---@class CharacterGameTableGame: MatchGroupUtilGame
---@field picks string[][]
---@field bans string[][]?
---@field pickedBy number?
---@field pickedByplayer number?

---@class CharacterGameTableMatch: MatchTableMatch
---@field games CharacterGameTableGame[]

---@class CharacterGameTable: GameTable
---@operator call(table): CharacterGameTable
---@field character string
---@field isCharacterTable boolean
---@field isPickedByRequired boolean
---@field config CharacterGameTableConfig
---@field matches CharacterGameTableMatch[]
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
		assert(Namespace.isMain(self.title), 'Lua.importd character= argument')
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
	return Logic.isNotEmpty(side) and 'brkts-popup-side-color brkts-popup-side-color--' .. side or nil
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

---@param game MatchGroupUtilGame
---@return boolean
function CharacterGameTable:filterGame(game)
	---@cast game CharacterGameTableGame
	game.picks = self:getCharacters(game, self.config.numPicks, self.getCharacterKey)
	game.bans = self.config.showBans and
		self:getCharacters(game, self.config.numBans,self.getCharacterBanKey) or nil
	game.pickedBy = self.isPickedByRequired and self:getCharacterPick(game) or nil

	if self.isPickedByRequired then
		return Logic.isNotEmpty(game.pickedBy)
	end

	local foundPicks = Table.isNotEmpty(game.picks[1]) or Table.isNotEmpty(game.picks[2])
	return foundPicks or self.config.showGameWithoutCharacters
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

---@protected
---@return table[]
function CharacterGameTable:buildColumnDefinitions()
	local config = self.config
	local isCharTable = self.isCharacterTable
	return WidgetUtil.collect(
		{
			-- Date column
			align = 'left',
			sortType = 'number',
		},
		config.showTier and {align = 'left'} or nil,
		config.showType and {align = 'center'} or nil,
		config.displayGameIcons and {align = 'center'} or nil,
		config.showIcon and {
			align = 'center',
			unsortable = true,
		} or nil,
		{
			-- Tournament column
			align = 'left',
		},
		config.showResult and WidgetUtil.collect(
			not isCharTable and {align = 'center'} or nil,
			{
				align = 'center',
				unsortable = true,
			},
			config.showBans and {
				align = 'center',
				unsortable = true
			} or nil,
			isCharTable and {
				{align = 'center'},
				{align = 'center'},
				{align = 'center'},
			} or nil,
			{
				align = 'center',
				unsortable = true,
			},
			config.showBans and {
				align = 'center',
				unsortable = true
			} or nil
		) or nil,
		config.showLength and {
			align = 'left',
			unsortable = true,
		} or nil,
		config.showVod and {
			align = 'left',
			unsortable = true,
		} or nil,
		config.showMatchPage and {
			align = 'center',
			unsortable = true,
		} or nil
	)
end

---@return Widget
function CharacterGameTable:headerRow()
	---@param text string?
	---@return Widget
	local makeHeaderCell = function(text)
		return TableWidgets.CellHeader{children = text}
	end

	local config = self.config
	local isCharTable = self.isCharacterTable

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			makeHeaderCell('Date'),
			config.showTier and makeHeaderCell('Tier') or nil,
			config.showType and makeHeaderCell('Type') or nil,
			config.displayGameIcons and makeHeaderCell() or nil,
			config.showIcon and makeHeaderCell() or nil,
			makeHeaderCell('Tournament'),
			config.showResult and WidgetUtil.collect(
			not isCharTable and makeHeaderCell('vs.') or nil,
			makeHeaderCell('Picks'),
			config.showBans and makeHeaderCell('Bans') or nil,
			isCharTable and {
				makeHeaderCell(),
				makeHeaderCell('Score'),
				makeHeaderCell(),
			} or nil,
			makeHeaderCell('vs. Picks'),
			config.showBans and makeHeaderCell('vs. Bans') or nil
		) or nil,
		config.showLength and makeHeaderCell('Length') or nil,
			config.showVod and TableWidgets.CellHeader{
				align = 'center',
				children = 'VOD'
			} or nil,
			config.showMatchPage and makeHeaderCell() or nil
		)}
	}}
end

---@param game CharacterGameTableGame
---@param opponentIndex number
---@param key string
---@return Widget?
function CharacterGameTable:_displayCharacters(game, opponentIndex, key)
	local config = self.config

	return TableWidgets.Cell{children = MatchSummaryCharacters{
		bg = config.showSideClass and self:getSideClass(game.extradata, opponentIndex) or nil,
		characters = game[key][opponentIndex] or {},
		date = game.date,
	}}
end

---@param match CharacterGameTableMatch
---@param game CharacterGameTableGame
---@return Widget[]?
function CharacterGameTable:displayGame(match, game)
	if not self.config.showResult then
		return
	end

	if self.isCharacterTable then
		local pickedBy = game.pickedBy
		---@cast pickedBy -nil
		local pickedVs = pickedBy == 1 and 2 or 1
		local opponentRecords = {match.result.opponent, match.result.vs}
		return WidgetUtil.collect(
			self:_displayDraft(game, opponentRecords[pickedBy], pickedBy, false),
			self:_displayScore(game, pickedBy, pickedVs),
			self:_displayDraft(game, opponentRecords[pickedVs], pickedVs, true)
		)

	else
		local indexes = match.result.flipped and {2, 1} or {1, 2}
		return WidgetUtil.collect(
			self:_displayOpponent(match.result.vs),
			self:_displayDraft(game, match.result.opponent, indexes[1]),
			self:_displayDraft(game, match.result.vs, indexes[2])
		)
	end
end

---@param game CharacterGameTableGame
---@param opponentRecord standardOpponent
---@param opponentIndex integer
---@param flipped boolean?
---@return Widget[]?
function CharacterGameTable:_displayDraft(game, opponentRecord, opponentIndex, flipped)
	local isCharTable = self.isCharacterTable
	local opponent = self:_displayOpponent(opponentRecord, flipped)
	return WidgetUtil.collect(
		(flipped and isCharTable) and opponent or nil,
		self:_displayCharacters(game, opponentIndex, 'picks'),
		self.config.showBans and self:_displayCharacters(game, opponentIndex, 'bans') or nil,
		(not flipped and isCharTable) and opponent or nil
	)
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
		return HtmlWidgets.Span{
			css = {['font-weight'] = isWinner and 'bold' or nil},
			children = scores[opponentId] or (isWinner and 'W' or 'L')
		}
	end

	return TableWidgets.Cell{children = {
		toScore(pickedBy),
		SCORE_CONCAT,
		toScore(pickedVs),
	}}
end

---@param game CharacterGameTableGame
---@return Html?
function CharacterGameTable:_displayLength(game)
	if not self.config.showLength then return end

	return TableWidgets.Cell{children = game.length}
end

---@param match CharacterGameTableMatch
---@param game CharacterGameTableGame
---@return Widget
function CharacterGameTable:gameRow(match, game)
	local indexes = ((self.isCharacterTable and game.pickedBy == game.winner) or match.result.flipped) and {2, 1} or {1, 2}
	local winner = game.winner == indexes[1]

	return TableWidgets.Row{
		classes = {self:_getBackgroundClass(winner)},
		children = WidgetUtil.collect(
			self:_displayDate(match),
			self:displayTier(match),
			self:_displayType(match),
			self:_displayGameIconForGame(game),
			self:_displayIcon(match),
			self:_displayTournament(match),
			self:displayGame(match, game),
			self:_displayGameVod(game.vod),
			self:_displayMatchPage(match)
		)
	}
end

---@param frame Frame
---@return Widget
function CharacterGameTable.results(frame)
	local args = Arguments.getArgs(frame)

	return CharacterGameTable(args):readConfig():query():build()
end

return CharacterGameTable

---
-- @Liquipedia
-- page=Module:GameHistory
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')

local Condition = Lua.import('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local GameTable = Lua.import('Module:GameTable')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local Link = Lua.import('Module:Widget/Basic/Link')
local MatchSummaryCharacters = Lua.import('Module:Widget/Match/Summary/Characters')
local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class GameHistoryConfig: MatchTableConfig
---@field picks string[]?
---@field picks2 string[]?
---@field bans string[]?
---@field patch string[]?
---@field publisherId string?
---@field showBans boolean
---@field showLength boolean
---@field showPatch boolean
---@field numPicks integer
---@field numBans integer

---@class GameHistoryGame: MatchGroupUtilGame
---@field picks string[][]
---@field bans string[][]

---@class GameHistoryMatch: MatchTableMatch
---@field games GameHistoryGame[]

---@class GameHistory: GameTable
---@operator call(table): GameHistory
---@field config GameHistoryConfig
---@field matches GameHistoryMatch[]
local GameHistory = Class.new(GameTable, function(self)
	local args = self.args
	args.tableMode = args.tableMode or Opponent.team

	if String.isNotEmpty(args.teams) then
		local teams = Array.parseCommaSeparatedString(args.teams)
		args.team = args.team or teams[1]
		args.vsteam = args.vsteam or teams[2]
	elseif String.isNotEmpty(args.picksteam) then
		args.team = args.team or args.picksteam
	end
end)

---@param frame Frame
---@return Widget
function GameHistory.create(frame)
	local args = Arguments.getArgs(frame)
	return GameHistory(args):readConfig():query():build()
end

---@return integer
function GameHistory:getNumberOfPicks()
	return 5
end

---@return integer
function GameHistory:getNumberOfBans()
	return 5
end

---@param opponentIndex integer
---@param playerIndex integer
---@return string
function GameHistory:getCharacterKey(opponentIndex, playerIndex)
	return 'team' .. opponentIndex .. 'champion' .. playerIndex
end

---@param opponentIndex integer
---@param playerIndex integer
---@return string
function GameHistory:getCharacterBanKey(opponentIndex, playerIndex)
	return 'team' .. opponentIndex .. 'ban' .. playerIndex
end

---@param game GameHistoryGame
---@param opponentIndex integer
---@return string[]
function GameHistory:getPicks(game, opponentIndex)
	return Array.map(Array.range(1, self.config.numPicks), function(playerIndex)
		return game.extradata[self:getCharacterKey(opponentIndex, playerIndex)]
	end)
end

---@param game GameHistoryGame
---@param opponentIndex integer
---@return string[]
function GameHistory:getBans(game, opponentIndex)
	return Array.map(Array.range(1, self.config.numBans), function(playerIndex)
		return game.extradata[self:getCharacterBanKey(opponentIndex, playerIndex)]
	end)
end

---@param extradata table
---@param opponentIndex integer
---@return string?
function GameHistory:getSideClass(extradata, opponentIndex)
	local side = extradata['team' .. opponentIndex .. 'side']
	return Logic.isNotEmpty(side) and 'brkts-popup-side-color brkts-popup-side-color--' .. side or nil
end

---@return self
function GameHistory:readConfig()
	GameTable.readConfig(self)

	local args = self.args
	self.config = Table.merge(self.config, {
		picks = String.isNotEmpty(args.picks) and Array.parseCommaSeparatedString(args.picks) or nil,
		picks2 = String.isNotEmpty(args.picks2) and Array.parseCommaSeparatedString(args.picks2) or nil,
		bans = String.isNotEmpty(args.bans) and Array.parseCommaSeparatedString(args.bans) or nil,
		patch = String.isNotEmpty(args.patch) and Array.parseCommaSeparatedString(args.patch) or nil,
		publisherId = String.nilIfEmpty(args.publisherid),
		showBans = Logic.nilOr(Logic.readBoolOrNil(args.showBans), true),
		showLength = Logic.readBool(args.length),
		showPatch = Logic.nilOr(Logic.readBoolOrNil(args.showPatch), true),
		numPicks = self:getNumberOfPicks(),
		numBans = self:getNumberOfBans(),
	})

	return self
end

---@param keyMaker fun(self: GameHistory, opponentIndex: integer, playerIndex: integer): string
---@param maxNumber integer
---@param characters string[]
---@return ConditionTree
function GameHistory:_buildCharacterListConditions(keyMaker, maxNumber, characters)
	local conditions = ConditionTree(BooleanOperator.any)
	Array.forEach({1, 2}, function(opponentIndex)
		Array.forEach(Array.range(1, maxNumber), function(playerIndex)
			Array.forEach(characters, function(character)
				conditions:add(ConditionNode(
					ColumnName(keyMaker(self, opponentIndex, playerIndex), 'extradata'),
					Comparator.eq,
					character
				))
			end)
		end)
	end)
	return conditions
end

---@param opponentIndex integer
---@param maxNumber integer
---@param characters string[]
---@return ConditionTree
function GameHistory:_buildSideCharacterConditions(opponentIndex, maxNumber, characters)
	local conditions = ConditionTree(BooleanOperator.any)
	Array.forEach(Array.range(1, maxNumber), function(playerIndex)
		Array.forEach(characters, function(character)
			conditions:add(ConditionNode(
				ColumnName(self:getCharacterKey(opponentIndex, playerIndex), 'extradata'),
				Comparator.eq,
				character
			))
		end)
	end)
	return conditions
end

---@param picks string[]
---@param picks2 string[]
---@return ConditionTree
function GameHistory:_buildHeadToHeadPickConditions(picks, picks2)
	local numPicks = self.config.numPicks
	return ConditionTree(BooleanOperator.any)
		:add(ConditionTree(BooleanOperator.all)
			:add(self:_buildSideCharacterConditions(1, numPicks, picks))
			:add(self:_buildSideCharacterConditions(2, numPicks, picks2)))
		:add(ConditionTree(BooleanOperator.all)
			:add(self:_buildSideCharacterConditions(1, numPicks, picks2))
			:add(self:_buildSideCharacterConditions(2, numPicks, picks)))
end

---@param game GameHistoryGame
---@param opponentIndex integer
---@param keyMaker fun(self: GameHistory, opponentIndex: integer, playerIndex: integer): string
---@param maxNumber integer
---@param characters string[]
---@return boolean
function GameHistory:_sideHasCharacter(game, opponentIndex, keyMaker, maxNumber, characters)
	return Array.any(Array.range(1, maxNumber), function(playerIndex)
		local value = game.extradata[keyMaker(self, opponentIndex, playerIndex)]
		return value ~= nil and Table.includes(characters, value)
	end)
end

---@param game GameHistoryGame
---@return boolean
function GameHistory:_gameMatchesFilters(game)
	local config = self.config

	if config.picks and config.picks2 then
		local forward = self:_sideHasCharacter(game, 1, self.getCharacterKey, config.numPicks, config.picks)
			and self:_sideHasCharacter(game, 2, self.getCharacterKey, config.numPicks, config.picks2)
		local reverse = self:_sideHasCharacter(game, 1, self.getCharacterKey, config.numPicks, config.picks2)
			and self:_sideHasCharacter(game, 2, self.getCharacterKey, config.numPicks, config.picks)
		if not (forward or reverse) then
			return false
		end
	elseif config.picks then
		if not (self:_sideHasCharacter(game, 1, self.getCharacterKey, config.numPicks, config.picks)
			or self:_sideHasCharacter(game, 2, self.getCharacterKey, config.numPicks, config.picks)) then
			return false
		end
	elseif config.picks2 then
		if not (self:_sideHasCharacter(game, 1, self.getCharacterKey, config.numPicks, config.picks2)
			or self:_sideHasCharacter(game, 2, self.getCharacterKey, config.numPicks, config.picks2)) then
			return false
		end
	end

	if config.bans then
		if not (self:_sideHasCharacter(game, 1, self.getCharacterBanKey, config.numBans, config.bans)
			or self:_sideHasCharacter(game, 2, self.getCharacterBanKey, config.numBans, config.bans)) then
			return false
		end
	end

	if config.patch and not Table.includes(config.patch, game.patch) then
		return false
	end

	if config.publisherId and tostring(game.extradata.publisherid) ~= config.publisherId then
		return false
	end

	return true
end

---@return boolean
function GameHistory:_needsGameFilterQuery()
	local config = self.config
	return config.picks ~= nil or config.picks2 ~= nil or config.bans ~= nil
		or config.patch ~= nil or config.publisherId ~= nil
end

---@return ConditionTree
function GameHistory:_buildGameFilterConditions()
	local config = self.config
	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('winner'), Comparator.neq, '')}

	if config.picks and config.picks2 then
		-- This part to make the search only picks vs picks2, not picks and picks2
		conditions:add(self:_buildHeadToHeadPickConditions(config.picks, config.picks2))
	elseif config.picks then
		conditions:add(self:_buildCharacterListConditions(self.getCharacterKey, config.numPicks, config.picks))
	elseif config.picks2 then
		conditions:add(self:_buildCharacterListConditions(self.getCharacterKey, config.numPicks, config.picks2))
	end
	if config.bans then
		conditions:add(self:_buildCharacterListConditions(self.getCharacterBanKey, config.numBans, config.bans))
	end
	if config.patch then
		conditions:add(ConditionUtil.anyOf(ColumnName('patch'), config.patch))
	end
	if config.publisherId then
		conditions:add(ConditionNode(ColumnName('publisherid', 'extradata'), Comparator.eq, config.publisherId))
	end

	return conditions
end

---@return ConditionTree
function GameHistory:buildConditions()
	if not self:_needsGameFilterQuery() then
		return GameTable.buildConditions(self)
	end

	local lpdbData = mw.ext.LiquipediaDB.lpdb('match2game', {
		conditions = tostring(self:_buildGameFilterConditions()),
		query = 'match2id',
		order = 'date desc',
		groupby = 'match2id asc',
		limit = self.config.limit,
	})

	local matchIdConditions = ConditionTree(BooleanOperator.any)
	Array.forEach(lpdbData, function(game)
		matchIdConditions:add(ConditionNode(ColumnName('match2id'), Comparator.eq, game.match2id))
	end)

	return ConditionTree(BooleanOperator.all)
		:add(ConditionNode(ColumnName('finished'), Comparator.eq, 1))
		:add(self:buildDateConditions())
		:add(self:buildOpponentConditions())
		:add(self:buildAdditionalConditions())
		:add(matchIdConditions)
end

---@param game MatchGroupUtilGame
---@return boolean
function GameHistory:filterGame(game)
	if game.status == 'notplayed' or Logic.isEmpty(game.winner) then
		return false
	end
	---@cast game GameHistoryGame

	if not self:_gameMatchesFilters(game) then
		return false
	end

	game.picks = {self:getPicks(game, 1), self:getPicks(game, 2)}
	game.bans = {self:getBans(game, 1), self:getBans(game, 2)}

	return true
end

---@param game GameHistoryGame
---@param opponentIndex integer
---@param key 'picks'|'bans'
---@return Widget
function GameHistory:_displayCharacters(game, opponentIndex, key)
	return TableWidgets.Cell{
		classes = key == 'bans' and {'lor-graycard'} or nil,
		children = MatchSummaryCharacters{
			bg = self:getSideClass(game.extradata, opponentIndex),
			characters = game[key][opponentIndex] or {},
			date = game.date,
		}
	}
end

-- This function is for checking where the position of the hero should be
-- if picks == Leo, then the Leo will be on the picks row 1
-- if picks2 == Leo, then the Leo will be on the picks row 2
---@param game GameHistoryGame
---@param fallbackIndexes integer[]
---@return integer[]
function GameHistory:_gamePickOrderIndexes(game, fallbackIndexes)
	local config = self.config

	if config.picks and config.picks2 then
		local side1HasPicks = self:_sideHasCharacter(game, 1, self.getCharacterKey, config.numPicks, config.picks)
		local side2HasPicks2 = self:_sideHasCharacter(game, 2, self.getCharacterKey, config.numPicks, config.picks2)
		if side1HasPicks and side2HasPicks2 then
			return {1, 2}
		end
		local side2HasPicks = self:_sideHasCharacter(game, 2, self.getCharacterKey, config.numPicks, config.picks)
		local side1HasPicks2 = self:_sideHasCharacter(game, 1, self.getCharacterKey, config.numPicks, config.picks2)
		if side2HasPicks and side1HasPicks2 then
			return {2, 1}
		end
		return fallbackIndexes
	end

	local picks = config.picks or config.picks2
	if not picks then
		return fallbackIndexes
	end

	local side1HasPick = self:_sideHasCharacter(game, 1, self.getCharacterKey, config.numPicks, picks)
	local side2HasPick = self:_sideHasCharacter(game, 2, self.getCharacterKey, config.numPicks, picks)

	if side1HasPick and not side2HasPick then
		return {1, 2}
	elseif side2HasPick and not side1HasPick then
		return {2, 1}
	end

	return fallbackIndexes
end

---@param match GameHistoryMatch
---@param game GameHistoryGame
---@return Widget[]?
function GameHistory:displayGame(match, game)
	if not self.config.showResult then
		return
	elseif Logic.isEmpty(match.result.vs) then
		return self:nonStandardMatch(match)
	end

	local matchIndexes = match.result.flipped and {2, 1} or {1, 2}
	local opponentForRawIndex = {}
	opponentForRawIndex[matchIndexes[1]] = match.result.opponent
	opponentForRawIndex[matchIndexes[2]] = match.result.vs

	local displayIndexes = self:_gamePickOrderIndexes(game, matchIndexes)

	local winnerIndex = tonumber(game.winner)
	local winnerOpponent = opponentForRawIndex[winnerIndex]

	return WidgetUtil.collect(
		self:_displayOpponent(opponentForRawIndex[displayIndexes[1]], true),
		self:_displayCharacters(game, displayIndexes[1], 'picks'),
		self.config.showBans and self:_displayCharacters(game, displayIndexes[1], 'bans') or nil,
		self:_displayOpponent(opponentForRawIndex[displayIndexes[2]]),
		self:_displayCharacters(game, displayIndexes[2], 'picks'),
		self.config.showBans and self:_displayCharacters(game, displayIndexes[2], 'bans') or nil,
		TableWidgets.Cell{
			children = winnerOpponent and OpponentDisplay.InlineOpponent{
				opponent = winnerOpponent, teamStyle = self.config.teamStyle,
			} or nil,
		}
	)
end

---@param game GameHistoryGame
---@return Widget?
function GameHistory:_displayLength(game)
	if not self.config.showLength then return end
	return TableWidgets.Cell{children = game.length}
end

---@param game GameHistoryGame
---@return Widget?
function GameHistory:_displayPatch(game)
	if not self.config.showPatch then return end
	if Logic.isEmpty(game.patch) then
		return TableWidgets.Cell{}
	end
	return TableWidgets.Cell{children = Link{link = 'Patch ' .. game.patch, children = game.patch}}
end

---@param match GameHistoryMatch
---@param game GameHistoryGame
---@return Widget
function GameHistory:gameRow(match, game)
	return TableWidgets.Row{
		children = WidgetUtil.collect(
			self:_displayDate(match),
			self:displayTier(match),
			self:_displayType(match),
			self:_displayGameIconForGame(game),
			self:_displayIcon(match),
			self:_displayTournament(match),
			self:displayGame(match, game),
			self:_displayLength(game),
			self:_displayPatch(game),
			self:_displayGameVod(game.vod),
			self:_displayMatchPage(match)
		)
	}
end

---@protected
---@return table[]
function GameHistory:buildColumnDefinitions()
	local config = self.config
	return WidgetUtil.collect(
		{align = 'left', sortType = 'number'},
		config.showTier and {align = 'left'} or nil,
		config.showType and {align = 'center'} or nil,
		config.displayGameIcons and {align = 'center'} or nil,
		config.showIcon and {align = 'center', unsortable = true} or nil,
		{align = 'left'},
		config.showResult and WidgetUtil.collect(
			{align = 'left'},
			{align = 'center', unsortable = true},
			config.showBans and {align = 'center', unsortable = true} or nil,
			{align = 'left'},
			{align = 'center', unsortable = true},
			config.showBans and {align = 'center', unsortable = true} or nil,
			{align = 'left'}
		) or nil,
		config.showLength and {align = 'right'} or nil,
		config.showPatch and {align = 'center'} or nil,
		config.showVod and {align = 'left', unsortable = true} or nil	,
		config.showMatchPage and {align = 'center', unsortable = true} or nil
	)
end

---@return Widget
function GameHistory:headerRow()
	local config = self.config

	return TableWidgets.TableHeader{children = {
		TableWidgets.Row{children = WidgetUtil.collect(
			TableWidgets.CellHeader{children = 'Date'},
			config.showTier and TableWidgets.CellHeader{children = 'Tier'} or nil,
			config.showType and TableWidgets.CellHeader{children = 'Type'} or nil,
			config.displayGameIcons and TableWidgets.CellHeader{} or nil,
			config.showIcon and TableWidgets.CellHeader{} or nil,
			TableWidgets.CellHeader{children = 'Tournament'},
			config.showResult and WidgetUtil.collect(
				TableWidgets.CellHeader{children = 'Team'},
				TableWidgets.CellHeader{children = 'Picks'},
				config.showBans and TableWidgets.CellHeader{children = 'Bans'} or nil,
				TableWidgets.CellHeader{children = 'Team'},
				TableWidgets.CellHeader{children = 'Picks'},
				config.showBans and TableWidgets.CellHeader{children = 'Bans'} or nil,
				TableWidgets.CellHeader{children = 'Winner'}
			) or nil,
			config.showLength and TableWidgets.CellHeader{children = 'Length'} or nil,
			config.showPatch and TableWidgets.CellHeader{children = 'Patch'} or nil,
			config.showVod and TableWidgets.CellHeader{children = 'VOD'} or nil,
			config.showMatchPage and TableWidgets.CellHeader{} or nil
		)}
	}}
end

return GameHistory

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
local Operator = Lua.import('Module:Operator')
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

local CharacterGameTable = Lua.import('Module:GameTable/Character/Custom')
local TournamentStructure = Lua.import('Module:TournamentStructure')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local DEFAULT_LIMIT = 100
local GAME_QUERY_LIMIT = 5000

---@class GameHistoryConfig: CharacterGameTableConfig
---@field picks string[]?
---@field picks2 string[]?
---@field bansFilter string[]?
---@field patch string[]?
---@field publisherId string?
---@field matchGroupsSpec MatchGroupsSpec?

---@class GameHistory: CharacterGameTable
---@operator call(table): GameHistory
---@field config GameHistoryConfig
local GameHistory = Class.new(CharacterGameTable, function (self)
	local args = self.args
	args.tableMode = Opponent.team
	args.limit = args.limit or DEFAULT_LIMIT
	self.isCharacterTable = false
	self.isPickedByRequired = false

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
	return GameHistory(Arguments.getArgs(frame)):readConfig():query():build()
end

---Unlike a team page's match table, this is not scoped to "this page's team":
---without a team input it lists all teams, so no page-name fallback is applied.
---@protected
---@param mode MatchTableMode
---@return standardOpponent[]
function GameHistory:_readOpponents(mode)
	return Array.map(self:_readOpponentInputsFromBase('team'), function (input)
		return self:_readOpponent(mode, input)
	end)
end

---@param record MatchGroupUtilMatch
---@return MatchTableMatchResult?
function GameHistory:resultFromRecord(record)
	if #record.opponents ~= 2 or Table.isNotEmpty(self.config.aliases) then
		return CharacterGameTable.resultFromRecord(self, record)
	end

	local gameOpponents = Array.map(record.games, Operator.property('opponents'))

	return {
		opponent = record.opponents[1],
		vs = record.opponents[2],
		winner = record.winner,
		flipped = false,
		countGames = false,
		countRounds = false,
		gameOpponents = Array.map(gameOpponents, Operator.property(1)),
		gameVsOpponents = Array.map(gameOpponents, Operator.property(2)),
	}
end

---@return self
function GameHistory:readConfig()
	CharacterGameTable.readConfig(self)

	local args = self.args
	self.config = Table.merge(self.config, {
		picks = String.isNotEmpty(args.picks) and Array.parseCommaSeparatedString(args.picks) or nil,
		picks2 = String.isNotEmpty(args.picks2) and Array.parseCommaSeparatedString(args.picks2) or nil,
		bansFilter = String.isNotEmpty(args.bans) and Array.parseCommaSeparatedString(args.bans) or nil,
		patch = String.isNotEmpty(args.patch) and Array.parseCommaSeparatedString(args.patch) or nil,
		publisherId = String.nilIfEmpty(args.publisherid),
		matchGroupsSpec = self:_readMatchGroupsSpec(),
		showVod = Logic.nilOr(Logic.readBoolOrNil(args.vod), true),
		showLength = Logic.nilOr(Logic.readBoolOrNil(args.length), true),
	})

	return self
end

---@private
---@return MatchGroupsSpec?
function GameHistory:_readMatchGroupsSpec()
	local args = self.args
	if String.isEmpty(args.tournaments) then
		return TournamentStructure.readMatchGroupsSpec(args)
	end

	local tournamentArgs = {}
	Array.forEach(Array.parseCommaSeparatedString(args.tournaments), function (tournament, index)
		tournamentArgs['tournament' .. index] = tournament
	end)

	return TournamentStructure.readMatchGroupsSpec(tournamentArgs)
end

---Picks/bans/patch/publisherid are per game, so they are narrowed down on match2game first,
---and only the matches containing such a game are then queried on match2.
---@return ConditionTree?
function GameHistory:_buildGameConditions()
	local config = self.config
	if not (config.picks or config.picks2 or config.bansFilter or config.patch or config.publisherId) then
		return
	end

	local conditions = ConditionTree(BooleanOperator.all)
		:add{ConditionNode(ColumnName('winner'), Comparator.neq, '')}

	-- Only a necessary condition: picks vs picks2 on opposing sides is enforced in filterGame
	if config.picks then
		conditions:add(self:_buildCharacterListConditions(self.getCharacterKey, config.numPicks, config.picks))
	end
	if config.picks2 then
		conditions:add(self:_buildCharacterListConditions(self.getCharacterKey, config.numPicks, config.picks2))
	end
	if config.bansFilter then
		conditions:add(self:_buildCharacterListConditions(self.getCharacterBanKey, config.numBans, config.bansFilter))
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
	local baseConditions = CharacterGameTable.buildConditions(self)
	if self.config.matchGroupsSpec then
		baseConditions:add(TournamentStructure.getMatch2Filter(self.config.matchGroupsSpec))
	end
	local gameConditions = self:_buildGameConditions()
	if not gameConditions then
		return baseConditions
	end

	local lpdbData = mw.ext.LiquipediaDB.lpdb('match2game', {
		conditions = tostring(gameConditions),
		query = 'match2id',
		order = 'date desc',
		groupby = 'match2id asc',
		limit = GAME_QUERY_LIMIT,
	})

	local matchConditions = ConditionTree(BooleanOperator.any)
	Array.forEach(lpdbData, function (game)
		matchConditions:add(ConditionNode(ColumnName('match2id'), Comparator.eq, game.match2id))
	end)
	-- An empty tree would not restrict the match query at all, so make "no game found" match nothing
	if Logic.isEmpty(lpdbData) then
		matchConditions:add(ConditionNode(ColumnName('match2id'), Comparator.eq, ''))
	end

	return ConditionTree(BooleanOperator.all)
		:add(baseConditions)
		:add(matchConditions)
end

---@protected
---@param game CharacterGameTableGame
---@param opponentIndex number
---@param characters string[]
---@return boolean
function GameHistory:_hasPick(game, opponentIndex, characters)
	return self:_sideHasAnyCharacter(game, opponentIndex, self.getCharacterKey, self.config.numPicks, characters)
end

---@param game CharacterGameTableGame
---@return boolean
function GameHistory:_passesPickFilter(game)
	local config = self.config

	if config.picks and config.picks2 then
		return (self:_hasPick(game, 1, config.picks) and self:_hasPick(game, 2, config.picks2))
			or (self:_hasPick(game, 2, config.picks) and self:_hasPick(game, 1, config.picks2))
	end

	local characters = config.picks or config.picks2
	return not characters or self:_hasPick(game, 1, characters) or self:_hasPick(game, 2, characters)
end

---@param game MatchGroupUtilGame
---@return boolean
function GameHistory:filterGame(game)
	if not CharacterGameTable.filterGame(self, game) then
		return false
	end
	---@cast game CharacterGameTableGame
	local config = self.config

	if not self:_passesPickFilter(game) then
		return false
	end

	if config.bansFilter
		and not self:_sideHasAnyCharacter(game, 1, self.getCharacterBanKey, config.numBans, config.bansFilter)
		and not self:_sideHasAnyCharacter(game, 2, self.getCharacterBanKey, config.numBans, config.bansFilter) then
		return false
	end

	if config.patch and not Array.any(config.patch, function (patch) return patch == game.patch end) then
		return false
	end

	return not config.publisherId or tostring(game.extradata.publisherid) == config.publisherId
end

---The side picking the searched character(s) is displayed first, which can differ per game.
---@param game CharacterGameTableGame
---@param fallback integer[]
---@return integer[]
function GameHistory:_getPickOrder(game, fallback)
	local config = self.config

	if config.picks and config.picks2 then
		-- filterGame already made sure it is either this way around or the reverse
		return self:_hasPick(game, 1, config.picks) and self:_hasPick(game, 2, config.picks2) and {1, 2} or {2, 1}
	end

	local characters = config.picks or config.picks2
	if not characters then
		return fallback
	end

	local side1Picked = self:_hasPick(game, 1, characters)
	local side2Picked = self:_hasPick(game, 2, characters)
	if side1Picked and not side2Picked then
		return {1, 2}
	elseif side2Picked and not side1Picked then
		return {2, 1}
	end

	return fallback
end

---@protected
---@return table[]
function GameHistory:buildResultColumnDefinitions()
	local config = self.config
	return WidgetUtil.collect(
		{align = 'left'},
		{align = 'center', unsortable = true},
		config.showBans and {align = 'center', unsortable = true} or nil,
		{align = 'left'},
		{align = 'center', unsortable = true},
		config.showBans and {align = 'center', unsortable = true} or nil,
		{align = 'center'}
	)
end

---@protected
---@return Widget[]
function GameHistory:buildResultHeaderCells()
	local config = self.config
	return WidgetUtil.collect(
		TableWidgets.CellHeader{children = 'Team'},
		TableWidgets.CellHeader{children = 'Picks'},
		config.showBans and TableWidgets.CellHeader{children = 'Bans'} or nil,
		TableWidgets.CellHeader{children = 'Team'},
		TableWidgets.CellHeader{children = 'Picks'},
		config.showBans and TableWidgets.CellHeader{children = 'Bans'} or nil,
		TableWidgets.CellHeader{children = 'Winner'}
	)
end

---@param match CharacterGameTableMatch
---@param game CharacterGameTableGame
---@return Widget[]?
function GameHistory:displayGame(match, game)
	if not self.config.showResult then
		return
	elseif Logic.isEmpty(match.result.vs) then
		return self:nonStandardMatch(match)
	end

	local matchIndexes = match.result.flipped and {2, 1} or {1, 2}
	local opponents = {}
	opponents[matchIndexes[1]] = match.result.opponent
	opponents[matchIndexes[2]] = match.result.vs

	local order = self:_getPickOrder(game, matchIndexes)
	local winner = opponents[tonumber(game.winner)]

	return WidgetUtil.collect(
		self:_displayOpponent(opponents[order[1]], true),
		self:_displayCharacters(game, order[1], 'picks'),
		self.config.showBans and self:_displayCharacters(game, order[1], 'bans') or nil,
		self:_displayOpponent(opponents[order[2]]),
		self:_displayCharacters(game, order[2], 'picks'),
		self.config.showBans and self:_displayCharacters(game, order[2], 'bans') or nil,
		winner and self:_displayOpponent(winner) or TableWidgets.Cell{}
	)
end

return GameHistory
